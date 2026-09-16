import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/alerts/validation_card.dart';

class ConfirmAlertsScreen extends ConsumerWidget {
  const ConfirmAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximityAlerts = ref.watch(proximityNotifierProvider);
    final currentLocation = ref.watch(currentLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirmar Alertas',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: proximityAlerts.isEmpty
          ? _buildEmptyState(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Text(
                    'Ayuda a mantener el mapa actualizado validando los reportes en tu zona. Tu colaboración mejora la seguridad de todos.',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: proximityAlerts.length,
                    itemBuilder: (context, index) {
                      final incident = proximityAlerts[index];
                      return ValidationCard(
                        incident: incident,
                        currentLocation: currentLocation,
                        onStillThere: () {
                          ref
                              .read(proximityNotifierProvider.notifier)
                              .dismissAlert(incident.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gracias por confirmar.'),
                            ),
                          );
                        },
                        onResolved: () async {
                          final user = ref.read(authProvider);
                          if (user != null) {
                            await ref
                                .read(incidentsProvider.notifier)
                                .validateIncident(incident.id, user.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Incidente solucionado (+5 puntos)'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                          ref
                              .read(proximityNotifierProvider.notifier)
                              .permanentlyDismissAlert(incident.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: AppColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Todo en orden!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay alertas pendientes por confirmar cerca de tu ubicación actual.',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
