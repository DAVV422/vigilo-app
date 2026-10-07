import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../domain/entities/citizen_summary.dart';
import '../domain/entities/recycling_listing.dart';
import '../domain/entities/recycling_pickup.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';
import '../presentation/screens/recycling/pickup_detail_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/main_app_bar.dart';

/// Reescrito contra `RecyclingRepository`. Antes los 3 contadores de resumen
/// estaban fijos en 0 y las "alertas disponibles" eran 4 tarjetas
/// hardcodeadas — ni siquiera consistentes con el estado vacío mostrado
/// arriba de ellas en el mismo diseño.
class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  List<RecyclingPickup> _activePickups = [];
  List<RecyclingListing> _nearbyListings = [];
  CitizenSummary? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider);
    if (user == null || !user.roles.contains(UserRole.recycling)) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final location = ref.read(currentLocationProvider);
      final results = await Future.wait([
        ref.read(recyclingRepositoryProvider).getMyPickups(filter: 'active'),
        ref.read(recyclingRepositoryProvider).getNearbyListings(
              latitude: location.latitude,
              longitude: location.longitude,
              radiusKm: 10,
            ),
        ref.read(analyticsRepositoryProvider).getCitizenSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _activePickups = results[0] as List<RecyclingPickup>;
        _nearbyListings = results[1] as List<RecyclingListing>;
        _summary = results[2] as CitizenSummary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'No se pudo cargar tus recolecciones.';
        _isLoading = false;
      });
    }
  }

  Future<void> _claim(String listingId) async {
    try {
      await ref.read(recyclingRepositoryProvider).claimListing(listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación reservada. Coordina el recojo con el ciudadano.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'No se pudo reservar la publicación.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isRecycler = user?.roles.contains(UserRole.recycling) ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(title: 'Mis recolecciones'),
      body: !isRecycler
          ? _buildNotRecyclerState()
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? _buildError(_error!)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        children: [
                          _buildSummaryRow(),
                          const SizedBox(height: 20),
                          _buildActivePickups(),
                          const SizedBox(height: 24),
                          const Text(
                            'Publicaciones cercanas disponibles',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 12),
                          ..._nearbyListings.map(_buildListingCard),
                          if (_nearbyListings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No hay publicaciones cercanas por ahora.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildNotRecyclerState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.recycling_outlined, color: AppColors.outline, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Activa el rol de reciclador en tu perfil para ver y reservar recolecciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
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

  Widget _buildSummaryRow() {
    final kg = _summary?.recycledAsRecyclerKg ?? 0;
    return Row(
      children: [
        _summaryCard('${_activePickups.length}', 'Pendientes'),
        const SizedBox(width: 8),
        _summaryCard('${_summary?.pickupsCompletedAsRecycler ?? 0}', 'Completadas'),
        const SizedBox(width: 8),
        _summaryCard('${kg.toStringAsFixed(1)}kg', 'Kg recuperados'),
      ],
    );
  }

  Widget _summaryCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: AppColors.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePickups() {
    if (_activePickups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.outline, size: 32),
            SizedBox(height: 8),
            Text('No tienes recolecciones pendientes', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: _activePickups
          .map(
            (pickup) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => PickupDetailScreen(pickupId: pickup.id)),
                  );
                  if (changed == true) await _load();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pickup.listingAddress ?? 'Dirección no disponible', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(pickup.status, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListingCard(RecyclingListing listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.recycling, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.materials.map((m) => m.materialName ?? 'Material').join(', '),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(listing.approximateAddress ?? 'Zona aproximada', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _claim(listing.id),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
  }
}
