import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recycling_listing.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/ratings/rate_pickup_sheet.dart';
import 'pickup_confirmation_screen.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';

/// El ciudadano no tenía ninguna forma de ver sus propias publicaciones ni
/// de descubrir cuáles ya tienen un pesaje esperando su confirmación —
/// dependía por completo de recibir y tocar la notificación push. Esta
/// pantalla las lista directamente.
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  static const _log = AppLogger('MisPublicaciones');
  List<RecyclingListing> _listings = [];

  /// Recojos que este usuario ya calificó, para no volver a ofrecérselos.
  /// Sale de `GET /ratings/mine`: el servidor es quien lo sabe, no el
  /// teléfono. Guardarlo localmente habría sido más barato pero el dato es
  /// del usuario, y quien reinstala volvería a ver tarjetas de recojos que
  /// ya calificó.
  Set<String> _ratedPickupIds = {};
  bool _isLoading = true;
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
      // En paralelo: una no depende de la otra y son dos viajes de red.
      final (listings, rated) = await (
        ref.read(recyclingRepositoryProvider).getMyListings(),
        _loadRatedPickupIds(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _ratedPickupIds = rated;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = describeError(e, st, log: _log, operation: 'cargar tus publicaciones');
        _isLoading = false;
      });
    }
  }

  bool _needsConfirmation(RecyclingListing listing) {
    return listing.status == 'COMPLETED' && listing.pickupCompensationStatus == 'PENDING_CONFIRMATION';
  }

  Future<void> _openConfirmation(RecyclingListing listing) async {
    if (listing.pickupId == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PickupConfirmationScreen(pickupId: listing.pickupId!)),
    );
    if (changed == true) await _load();
  }

  (String, Color) _statusChip(RecyclingListing listing) {
    if (_needsConfirmation(listing)) return ('Esperando tu confirmación', AppColors.warning);
    switch (listing.status) {
      case 'PENDING':
        return ('Pendiente de reclamo', AppColors.onSurfaceVariant);
      case 'CLAIMED':
        return ('Reservada por un reciclador', AppColors.primary);
      case 'COMPLETED':
        return ('Completada', AppColors.success);
      case 'CANCELLED':
        return ('Cancelada', AppColors.error);
      case 'EXPIRED':
        return ('Expirada', AppColors.error);
      default:
        return (listing.status, AppColors.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis publicaciones')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(_error!)
              : _buildList(),
    );
  }

  /// Nunca hace fallar la pantalla: si no se pueden leer las calificaciones
  /// emitidas, lo peor que pasa es que se ofrezca calificar algo ya
  /// calificado, y ahí el 409 del servidor lo resuelve con un aviso.
  Future<Set<String>> _loadRatedPickupIds() async {
    try {
      final mine = await ref.read(ratingsRepositoryProvider).getMyRatings();
      return mine.map((r) => r.contextId).toSet();
    } catch (e) {
      _log.warning('No se pudieron leer las calificaciones emitidas: $e');
      return {};
    }
  }

  /// El recojo terminó y todavía no lo calificó.
  ///
  /// Se omite mientras la publicación esté esperando confirmación: ahí hay
  /// algo más urgente que hacer, y al confirmar ya aparece la hoja sola.
  /// Ofrecer las dos cosas en la misma tarjeta compite consigo misma y
  /// termina en un 409 cuando el usuario hace las dos.
  bool _canRate(RecyclingListing listing) {
    final pickupId = listing.pickupId;
    return pickupId != null &&
        listing.pickupRecyclerId != null &&
        listing.pickupStatus == 'COMPLETED' &&
        !_needsConfirmation(listing) &&
        !_ratedPickupIds.contains(pickupId);
  }

  Future<void> _rate(RecyclingListing listing) async {
    final done = await showRatePickupSheet(
      context,
      pickupId: listing.pickupId!,
      rateeId: listing.pickupRecyclerId!,
      rateeName: listing.pickupRecyclerName,
      rateeTrustScore: listing.pickupRecyclerTrustScore,
      rateeIsRecycler: true,
    );
    // Se agrega en memoria en vez de recargar todo: la tarjeta desaparece al
    // instante y nos ahorramos dos peticiones.
    if (done == true && mounted) {
      setState(() => _ratedPickupIds = {..._ratedPickupIds, listing.pickupId!});
    }
  }

  Widget _buildRateCard(RecyclingListing listing) {
    final who = listing.pickupRecyclerName ?? 'el recolector';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline_rounded, color: AppColors.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Contanos cómo te fue con $who',
              style: const TextStyle(fontSize: 13, color: AppColors.onPrimaryContainer),
            ),
          ),
          TextButton(
            onPressed: () => _rate(listing),
            // Color explícito: `primaryContainer` es verde oscuro en este
            // tema, y el verde por defecto del TextButton queda ilegible
            // encima.
            style: TextButton.styleFrom(foregroundColor: AppColors.onPrimaryContainer),
            child: const Text('Calificar'),
          ),
        ],
      ),
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

  Widget _buildList() {
    if (_listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.recycling_outlined, color: AppColors.outline, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Todavía no publicaste material reciclable.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          final listing = _listings[index];
          final (label, color) = _statusChip(listing);
          final actionable = _needsConfirmation(listing);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: actionable ? AppColors.warning : AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: actionable ? () => _openConfirmation(listing) : null,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.materials.map((m) => m.materialName ?? 'Material').join(', '),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(listing.address ?? '', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                      if (actionable) const Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
                    ],
                  ),
                  if (_canRate(listing)) _buildRateCard(listing),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
