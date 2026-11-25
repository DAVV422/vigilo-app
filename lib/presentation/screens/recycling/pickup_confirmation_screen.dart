import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recycling_pickup.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ratings/rate_pickup_sheet.dart';
import '../../../../core/errors/describe_error.dart';
import '../../../../core/logging/app_logger.dart';

/// El ciudadano revisa el pesaje que registró el recolector y confirma (se
/// acreditan los puntos) o disputa (si el peso/pago no coincide con lo
/// acordado). Se llega acá desde "Mis publicaciones" o desde una
/// notificación de tipo PICKUP_PENDING_CONFIRMATION.
class PickupConfirmationScreen extends ConsumerStatefulWidget {
  const PickupConfirmationScreen({super.key, required this.pickupId});

  final String pickupId;

  @override
  ConsumerState<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends ConsumerState<PickupConfirmationScreen> {
  static const _log = AppLogger('Recojo');
  RecyclingPickup? _pickup;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pickup = await ref.read(recyclingRepositoryProvider).getPickupById(widget.pickupId);
      if (!mounted) return;
      setState(() {
        _pickup = pickup;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = describeError(e, st, log: _log, operation: 'cargar el recojo');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _isActing = true);
    try {
      final result = await ref.read(recyclingRepositoryProvider).confirmPickup(widget.pickupId);
      await ref.read(authProvider.notifier).reloadUser();
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
              Text(
                '+${result.pointsAwarded} puntos acreditados',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Nuevo saldo: ${result.newPointsBalance} puntos',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Listo')),
              ),
            ],
          ),
        ),
      );
      // La hoja va DESPUES del dialogo, no en su lugar: la confirmacion de
      // que se acreditaron los puntos es lo que el usuario esta esperando, y
      // pisarla con un pedido de calificacion hace que la lea a medias.
      await _offerRating();
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(e, st, log: _log, operation: 'confirmar el recojo', whereToCheck: 'Mis Publicaciones');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  /// Ofrece calificar al recolector. Nunca bloquea ni falla el flujo: si el
  /// recojo no trae el id del recolector —backend anterior a P-02— se omite
  /// en silencio, porque el usuario ya consiguio lo que vino a hacer.
  Future<void> _offerRating() async {
    final pickup = _pickup;
    final recyclerId = pickup?.recyclerId;
    if (!mounted || pickup == null || recyclerId == null) return;
    await showRatePickupSheet(
      context,
      pickupId: pickup.id,
      rateeId: recyclerId,
      rateeName: pickup.recyclerName,
      rateeTrustScore: pickup.recyclerTrustScore,
      rateeIsRecycler: true,
    );
  }

  Future<void> _dispute() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disputar recojo'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Explica qué no coincide (peso, pago, etc.)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disputar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // El diálogo es un `await`: si la pantalla se cerró mientras estaba
    // abierto, `context` ya no sirve y el ScaffoldMessenger de abajo
    // revienta.
    if (!mounted) return;
    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un motivo para la disputa.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isActing = true);
    try {
      await ref.read(recyclingRepositoryProvider).disputePickup(
            pickupId: widget.pickupId,
            reason: reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disputa registrada. Un administrador la revisará.')),
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(e, st, log: _log, operation: 'registrar la disputa', whereToCheck: 'Mis Publicaciones');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar recojo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(_error!)
              : _buildContent(_pickup!),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecyclingPickup pickup) {
    final compensation = pickup.compensation;
    final alreadyResolved = compensation != null && compensation.status != 'PENDING_CONFIRMATION';
    final totalPoints = pickup.results.fold<int>(0, (sum, r) => sum + r.pointsAwarded);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(pickup.listingAddress ?? '', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        _sectionLabel('Pesaje registrado por el recolector'),
        ...pickup.results.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.materialName ?? 'Material', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${(r.actualWeightGrams / 1000).toStringAsFixed(2)} kg · +${r.pointsAwarded} pts',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (compensation != null) ...[
          _sectionLabel('Pago ofrecido'),
          Text('${compensation.paymentMethod} · Bs. ${compensation.grossAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
          child: Text(
            'Total a acreditar: +$totalPoints puntos',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 28),
        if (alreadyResolved)
          Text(
            compensation.status == 'CONFIRMED' ? 'Ya confirmaste este recojo.' : 'Ya disputaste este recojo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActing ? null : _confirm,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Confirmar recojo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isActing ? null : _dispute,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Disputar'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
