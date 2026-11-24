import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recycling_pickup.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'pickup_weigh_in_screen.dart';
import '../../../../core/errors/describe_error.dart';
import '../../../../core/logging/app_logger.dart';

/// Pantalla del reciclador para avanzar un recojo ya reservado: marcar que
/// va en camino, que llegó, y finalmente pesar el material (ver
/// [PickupWeighInScreen]). Antes de esto no existía ninguna pantalla para
/// estos pasos — "Mis recolecciones" solo dejaba reservar y listar, sin
/// forma de completar el recojo.
class PickupDetailScreen extends ConsumerStatefulWidget {
  const PickupDetailScreen({super.key, required this.pickupId});

  final String pickupId;

  @override
  ConsumerState<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends ConsumerState<PickupDetailScreen> {
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

  Future<void> _markEnRoute() async {
    await _runAction(() => ref.read(recyclingRepositoryProvider).markEnRoute(widget.pickupId));
  }

  Future<void> _markArrived() async {
    await _runAction(() => ref.read(recyclingRepositoryProvider).markArrived(widget.pickupId));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isActing = true);
    try {
      await action();
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      final message = describeError(e, st, log: _log, operation: 'actualizar el recojo', whereToCheck: 'Mis Recojos');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _goToWeighIn() async {
    final pickup = _pickup;
    if (pickup == null) return;
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PickupWeighInScreen(pickup: pickup)),
    );
    if (completed == true) await _load();
  }

  Future<void> _cancelPickup() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar recojo'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Motivo (opcional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar recojo', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() => ref.read(recyclingRepositoryProvider).cancelPickup(
          pickupId: widget.pickupId,
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
        ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del recojo')),
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

  String _statusLabel(String status) {
    switch (status) {
      case 'CLAIMED':
        return 'Reservado';
      case 'EN_ROUTE':
        return 'En camino';
      case 'ARRIVED':
        return 'Llegaste al lugar';
      case 'COMPLETED':
        return 'Completado';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Widget _buildContent(RecyclingPickup pickup) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.onPrimaryContainer),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(pickup.status),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Dirección'),
          Text(pickup.listingAddress ?? 'No disponible', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          _sectionLabel('Ciudadano'),
          Text(pickup.citizenName ?? 'No disponible', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (pickup.citizenPhone != null && pickup.citizenPhone!.isNotEmpty)
            Text(pickup.citizenPhone!, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          _sectionLabel('Material estimado por el ciudadano'),
          ...pickup.listingMaterials.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${m.materialName ?? 'Material'} — ${(m.estimatedWeightGrams / 1000).toStringAsFixed(1)} kg aprox.',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (pickup.status == 'COMPLETED') _buildCompletedSummary(pickup) else _buildActions(pickup),
        ],
      ),
    );
  }

  Widget _buildCompletedSummary(RecyclingPickup pickup) {
    final compensation = pickup.compensation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Pesaje registrado'),
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
        if (compensation != null) ...[
          const SizedBox(height: 12),
          _sectionLabel('Compensación'),
          Text('${compensation.paymentMethod} · Bs. ${compensation.grossAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            _compensationLabel(compensation.status),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _compensationColor(compensation.status)),
          ),
        ],
      ],
    );
  }

  String _compensationLabel(String status) {
    switch (status) {
      case 'PENDING_CONFIRMATION':
        return 'Esperando que el ciudadano confirme';
      case 'CONFIRMED':
        return 'Confirmado por el ciudadano';
      case 'DISPUTED':
        return 'Disputado por el ciudadano';
      default:
        return status;
    }
  }

  Color _compensationColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'DISPUTED':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildActions(RecyclingPickup pickup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pickup.status == 'CLAIMED')
          ElevatedButton.icon(
            onPressed: _isActing ? null : _markEnRoute,
            icon: const Icon(Icons.directions_car_outlined, size: 18),
            label: const Text('Marcar en camino'),
          ),
        if (pickup.status == 'EN_ROUTE')
          ElevatedButton.icon(
            onPressed: _isActing ? null : _markArrived,
            icon: const Icon(Icons.pin_drop_outlined, size: 18),
            label: const Text('Marcar llegada'),
          ),
        if (pickup.status == 'ARRIVED')
          ElevatedButton.icon(
            onPressed: _isActing ? null : _goToWeighIn,
            icon: const Icon(Icons.scale_outlined, size: 18),
            label: const Text('Registrar pesaje y completar'),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isActing ? null : _cancelPickup,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancelar recojo'),
        ),
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
