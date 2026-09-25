// lib/presentation/screens/alerts/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../widgets/alerts/alert_card.dart';
import '../../widgets/alerts/category_filter_row.dart';
import '../../widgets/alerts/create_alert_sheet.dart';
import '../../providers/providers.dart';
import 'alert_detail_screen.dart';
import '../../../domain/enums/alert_category.dart';
import '../../../domain/entities/incident.dart';
import '../../../widgets/main_app_bar.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertCategory? _selectedCategory;

  void _setCategoryFilter(AlertCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  AlertCategory _mapTypeToCategory(IncidentType type) {
    switch (type) {
      case IncidentType.insecurity:
        return AlertCategory.seguridad;
      case IncidentType.trash:
      case IncidentType.recycling:
        return AlertCategory.reciclaje;
      case IncidentType.weeds:
        return AlertCategory.maleza;
    }
  }

  IncidentType _mapCategoryToType(AlertCategory category) {
    switch (category) {
      case AlertCategory.seguridad:
        return IncidentType.insecurity;
      case AlertCategory.reciclaje:
        return IncidentType.recycling;
      case AlertCategory.maleza:
        return IncidentType.weeds;
    }
  }

  void _showCreateAlertModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CreateAlertSheet(
          onPublish: (title, description, category) async {
            final user = ref.read(authProvider);
            if (user == null) return;
            
            final newIncident = Incident(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              description: description,
              location: ref.read(currentLocationProvider),
              type: _mapCategoryToType(category),
              reportedAt: DateTime.now(),
              reportedByUserId: user.id,
              validatorsIds: [],
              status: IncidentStatus.active,
            );
            
            await ref.read(incidentsProvider.notifier).addIncident(newIncident);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIncidents = ref.watch(incidentsProvider);
    final user = ref.watch(authProvider);
    
    // Filtramos solo incidentes activos y por categoría si hay una seleccionada
    final alerts = allIncidents.where((incident) {
      if (incident.status != IncidentStatus.active) return false;
      if (_selectedCategory == null) return true;
      return _mapTypeToCategory(incident.type) == _selectedCategory;
    }).toList();
    
    // Ordenamos por fecha descendente
    alerts.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(title: 'Alertas'),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Fila de Filtros
          CategoryFilterRow(
            selectedCategory: _selectedCategory,
            onCategorySelected: _setCategoryFilter,
          ),
          const SizedBox(height: 8),

          // Lista de Alertas o Estado Vacío
          Expanded(
            child: alerts.isEmpty
                ? RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => ref.read(incidentsProvider.notifier).loadIncidents(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No hay alertas en esta categoría.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => ref.read(incidentsProvider.notifier).loadIncidents(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 80.0, // Espacio extra para que el FAB no tape la última tarjeta
                        left: 16.0,
                        right: 16.0,
                      ),
                      itemCount: alerts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final incident = alerts[index];
                        final isValidatedByMe = user != null && incident.validatorsIds.contains(user.id);
                        
                        return AlertCard(
                          incident: incident,
                          isValidatedByMe: isValidatedByMe,
                          onValidateTap: () {
                            if (user != null) {
                              ref.read(incidentsProvider.notifier).validateIncident(incident.id, user.id);
                            }
                          },
                          onViewTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlertDetailScreen(
                                  incident: incident,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAlertModal,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}
