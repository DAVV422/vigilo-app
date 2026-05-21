import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../domain/entities/incident.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

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

  void _navigateToMap(WidgetRef ref, Incident incident) {
    ref.read(selectedIncidentProvider.notifier).setIncident(incident);
    ref.read(currentNavIndexProvider.notifier).goToMap();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final allIncidents = ref.watch(incidentsProvider);

    if (currentUser == null) return const Scaffold(body: Center(child: Text('Inicia sesión')));

    final filteredIncidents = _filterIncidentsByRole(allIncidents, currentUser);
    filteredIncidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    String title = 'Alertas';
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
      ),
      backgroundColor: AppColors.background,
      body: filteredIncidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.isEmployee
                        ? 'No hay alertas para tu rol'
                        : 'No hay alertas activas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredIncidents.length,
              itemBuilder: (context, index) {
                final incident = filteredIncidents[index];

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

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _navigateToMap(ref, incident),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(typeIcon, color: typeColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        incident.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(incident.reportedAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.thumb_up, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('${incident.validatorsIds.length} validaciones', style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}