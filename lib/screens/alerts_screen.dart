import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../domain/entities/incident.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (mounted) {
        setState(() {
          _currentPosition = lastPosition;
          _isLoadingLocation = false;
        });
      }
    }
  }

  List<Incident> _filterIncidentsByRole(List<Incident> incidents, User? user) {
    if (user == null) return [];
    
    if (!user.isEmployee) {
      return incidents.where((i) => i.status == IncidentStatus.active).toList();
    }

    return incidents.where((i) {
      if (i.status == IncidentStatus.resolved) return false;
      
      switch (i.type) {
        case IncidentType.insecurity:
          return user.roles.contains(UserRole.security);
        case IncidentType.trash:
        case IncidentType.weeds:
          return user.roles.contains(UserRole.cleaning);
        case IncidentType.recycling:
          return user.roles.contains(UserRole.recycling);
      }
    }).toList();
  }

  void _navigateToMap(Incident incident) {
    ref.read(selectedIncidentProvider.notifier).setIncident(incident);
    ref.read(currentNavIndexProvider.notifier).goToMap();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return DateFormat('dd MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final allIncidents = ref.watch(incidentsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión')));
    }

    final filteredIncidents = _filterIncidentsByRole(allIncidents, currentUser);
    filteredIncidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    String title = 'Alertas Ciudadanas';
    if (currentUser.isEmployee) {
      if (currentUser.roles.contains(UserRole.security)) {
        title = 'Alertas de Seguridad';
      } else if (currentUser.roles.contains(UserRole.cleaning)) {
        title = 'Alertas de Limpieza';
      } else if (currentUser.roles.contains(UserRole.recycling)) {
        title = 'Alertas de Reciclaje';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _isLoadingLocation = true;
              });
              _getUserLocation();
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: filteredIncidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    currentUser.isEmployee
                        ? 'No hay alertas asignadas para tu rol'
                        : 'No hay alertas activas en tu ciudad',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '¡Buen trabajo manteniendo tu entorno limpio y seguro!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            )
          : usersAsync.when(
              data: (users) => ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredIncidents.length,
                itemBuilder: (context, index) {
                  final incident = filteredIncidents[index];
                  final reporter = users.firstWhere(
                    (u) => u.id == incident.reportedByUserId,
                    orElse: () => User(id: '', name: 'Desconocido', email: '', password: ''),
                  );

                  Color typeColor;
                  IconData typeIcon;
                  String typeLabel;
                  switch (incident.type) {
                    case IncidentType.insecurity:
                      typeColor = AppColors.secondary;
                      typeIcon = Icons.warning;
                      typeLabel = 'Seguridad';
                      break;
                    case IncidentType.trash:
                      typeColor = AppColors.neutralTrash;
                      typeIcon = Icons.delete;
                      typeLabel = 'Basura';
                      break;
                    case IncidentType.weeds:
                      typeColor = AppColors.warning;
                      typeIcon = Icons.grass;
                      typeLabel = 'Maleza';
                      break;
                    case IncidentType.recycling:
                      typeColor = AppColors.ecoGreen;
                      typeIcon = Icons.recycling;
                      typeLabel = 'Reciclaje';
                      break;
                  }

                  double? distanceInMeters;
                  if (_currentPosition != null) {
                    distanceInMeters = Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      incident.location.latitude,
                      incident.location.longitude,
                    );
                  }
                  final bool isWithinRange = distanceInMeters != null && distanceInMeters <= 200;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _navigateToMap(incident),
                        child: Column(
                          children: [
                            // Cabecera con gradiente sutil
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [typeColor.withOpacity(0.08), Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(typeIcon, color: typeColor, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          incident.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 11, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                reporter.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: TextStyle(
                                        color: typeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incident.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _timeAgo(incident.reportedAt),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.thumb_up_alt_outlined, size: 13, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${incident.validatorsIds.length}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 0.8),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (_isLoadingLocation)
                                        _buildInfoBadge(
                                          icon: Icons.radar,
                                          label: 'Cargando radar...',
                                          iconColor: Colors.grey,
                                          bgColor: Colors.grey.shade100,
                                          labelColor: Colors.grey.shade600,
                                        )
                                      else if (distanceInMeters != null)
                                        _buildInfoBadge(
                                          icon: isWithinRange ? Icons.radar : Icons.lock_outline,
                                          label: isWithinRange
                                              ? '${distanceInMeters.toInt()}m'
                                              : distanceInMeters < 1000
                                                  ? '${distanceInMeters.toInt()}m'
                                                  : '${(distanceInMeters / 1000).toStringAsFixed(1)}km',
                                          iconColor: isWithinRange ? AppColors.success : Colors.grey,
                                          bgColor: isWithinRange
                                              ? AppColors.success.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                          labelColor: isWithinRange ? AppColors.success : Colors.grey.shade600,
                                        )
                                      else
                                        _buildInfoBadge(
                                          icon: Icons.radar,
                                          label: 'Radar inactivo',
                                          iconColor: Colors.grey,
                                          bgColor: Colors.grey.shade100,
                                          labelColor: Colors.grey.shade600,
                                        ),
                                      const SizedBox(width: 8),
                                      _buildInfoBadge(
                                        icon: Icons.thumb_up_alt_outlined,
                                        label: '${incident.validatorsIds.length} val.',
                                        iconColor: AppColors.primary,
                                        bgColor: AppColors.primary.withOpacity(0.08),
                                        labelColor: AppColors.primary,
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Ver',
                                              style: TextStyle(
                                                color: typeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(Icons.open_in_new, size: 12, color: typeColor),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error al cargar usuarios')),
            ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}