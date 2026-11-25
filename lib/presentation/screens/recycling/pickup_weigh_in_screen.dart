import 'dart:io';
import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/recycling_pickup.dart';
import '../../../domain/repositories/recycling_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ratings/rate_pickup_sheet.dart';
import '../../../../core/errors/describe_error.dart';
import '../../../../core/logging/app_logger.dart';

class _PaymentOption {
  final String value;
  final String label;
  const _PaymentOption(this.value, this.label);
}

const _paymentOptions = [
  _PaymentOption('CASH', 'Efectivo'),
  _PaymentOption('YAPE', 'Yape'),
  _PaymentOption('PLIN', 'Plin'),
  _PaymentOption('TRANSFER', 'Transferencia'),
  _PaymentOption('POINTS_ONLY', 'Solo puntos'),
];

/// Pesaje real al completar un recojo: el recolector ajusta el peso real de
/// cada material (parte del estimado que publicó el ciudadano), elige cómo
/// pagó y cuánto, y opcionalmente adjunta una foto del voucher. Es el paso
/// que registra lo que el backend necesita para calcular puntos y
/// compensación — antes no existía ninguna pantalla que llegara hasta acá.
class PickupWeighInScreen extends ConsumerStatefulWidget {
  const PickupWeighInScreen({super.key, required this.pickup});

  final RecyclingPickup pickup;

  @override
  ConsumerState<PickupWeighInScreen> createState() => _PickupWeighInScreenState();
}

class _PickupWeighInScreenState extends ConsumerState<PickupWeighInScreen> {
  static const _log = AppLogger('Pesaje');
  late final Map<String, TextEditingController> _weightControllers;
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'CASH';
  XFile? _voucherImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _weightControllers = {
      for (final m in widget.pickup.listingMaterials)
        m.materialId: TextEditingController(text: (m.estimatedWeightGrams / 1000).toStringAsFixed(1)),
    };
  }

  @override
  void dispose() {
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickVoucher() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _voucherImage = picked);
  }

  /// Ofrece calificar al ciudadano. Si el recojo no trae su id se omite:
  /// el pesaje ya quedo registrado y eso es lo que importaba.
  Future<void> _offerRating() async {
    final citizenId = widget.pickup.citizenId;
    if (!mounted || citizenId == null) return;
    await showRatePickupSheet(
      context,
      pickupId: widget.pickup.id,
      rateeId: citizenId,
      rateeName: widget.pickup.citizenName,
      rateeTrustScore: widget.pickup.citizenTrustScore,
      rateeIsRecycler: false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  Future<void> _submit() async {
    final results = <ActualWeightInput>[];
    for (final entry in _weightControllers.entries) {
      final kg = double.tryParse(entry.value.text.replaceAll(',', '.'));
      if (kg == null || kg <= 0) {
        _showError('Ingresa un peso válido para cada material.');
        return;
      }
      results.add(ActualWeightInput(materialTypeId: entry.key, actualWeightGrams: kg * 1000));
    }

    final grossAmount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (grossAmount == null || grossAmount < 0) {
      _showError('Ingresa un monto válido (puede ser 0).');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? voucherMediaId;
      if (_voucherImage != null) {
        final uploaded = await ref.read(mediaRepositoryProvider).uploadImage(_voucherImage!.path, folder: 'pickups');
        voucherMediaId = uploaded.id;
      }

      final result = await ref.read(recyclingRepositoryProvider).completePickup(
            pickupId: widget.pickup.id,
            results: results,
            paymentMethod: _paymentMethod,
            grossAmount: grossAmount,
            voucherMediaId: voucherMediaId,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Recojo completado',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${result.totalPointsCalculated} puntos calculados para el ciudadano. '
                'Ahora debe confirmar el recojo para que se acrediten.',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      );
      // `completePickup` deja el recojo en COMPLETED, que es justo lo que
      // `POST /ratings` exige, asi que el recolector ya puede calificar.
      await _offerRating();
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      final message = describeError(e, st, log: _log, operation: 'registrar el pesaje', whereToCheck: 'Mis Recojos');
      _showError(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pesaje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Peso real por material'),
            ...widget.pickup.listingMaterials.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _weightControllers[m.materialId],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: m.materialName ?? 'Material',
                    suffixText: 'kg',
                    helperText: 'Estimado: ${(m.estimatedWeightGrams / 1000).toStringAsFixed(1)} kg',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sectionLabel('Método de pago'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentOptions
                  .map((opt) => ChoiceChip(
                        label: Text(opt.label),
                        selected: _paymentMethod == opt.value,
                        onSelected: (_) => setState(() => _paymentMethod = opt.value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Monto pagado'),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: 'Bs. ', hintText: '0 si es solo por puntos'),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Voucher (opcional)'),
            _buildVoucherPicker(),
            const SizedBox(height: 20),
            _sectionLabel('Notas (opcional)'),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Observaciones del recojo...'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(_isSubmitting ? 'Guardando...' : 'Completar recojo'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherPicker() {
    if (_voucherImage == null) {
      return OutlinedButton.icon(
        onPressed: _pickVoucher,
        icon: const Icon(Icons.camera_alt_outlined, size: 18),
        label: const Text('Tomar foto del voucher'),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(_voucherImage!.path), width: 64, height: 64, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: () => setState(() => _voucherImage = null), child: const Text('Quitar')),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurface),
      ),
    );
  }
}
