// lib/presentation/screens/alerts/alert_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/incident.dart';
import '../../../domain/enums/alert_category.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../providers/providers.dart';

class AlertDetailScreen extends ConsumerWidget {
  final Incident incident;

  const AlertDetailScreen({
    Key? key,
    required this.incident,
  }) : super(key: key);

  AlertCategory get _category {
    switch (incident.type) {
      case IncidentType.insecurity:
        return AlertCategory.seguridad;
      case IncidentType.trash:
      case IncidentType.recycling:
        return AlertCategory.reciclaje;
      case IncidentType.weeds:
        return AlertCategory.maleza;
    }
  }

  String get _formattedDate {
    final diff = DateTime.now().difference(incident.reportedAt);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return 'Hace ${diff.inDays} días';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el proveedor para que los "Me gusta" se actualicen en tiempo real
    final incidents = ref.watch(incidentsProvider);
    final currentIncident = incidents.firstWhere(
      (i) => i.id == incident.id,
      orElse: () => incident,
    );

    final user = ref.watch(authProvider);
    final isValidatedByMe = user != null && currentIncident.validatorsIds.contains(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            AppIcons.chevronLeft,
            color: AppColors.onBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalle de Alerta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Badge de Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _category.backgroundColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _category.icon,
                    size: 16,
                    color: _category.textColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _category.displayName,
                    style: TextStyle(
                      color: _category.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Título de la alerta
            Text(
              currentIncident.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Metadatos: Autor, Fecha y Validaciones
            Row(
              children: [
                const Icon(
                  AppIcons.person,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Por usuario',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  AppIcons.time,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                // Botón interactivo de validación
                InkWell(
                  onTap: () {
                    if (user != null) {
                      ref.read(incidentsProvider.notifier).validateIncident(currentIncident.id, user.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isValidatedByMe
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isValidatedByMe
                              ? AppIcons.thumbUpFilled
                              : AppIcons.thumbUp,
                          size: 16,
                          color: isValidatedByMe
                              ? AppColors.onPrimaryContainer
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${currentIncident.validatorsIds.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isValidatedByMe
                                ? AppColors.onPrimaryContainer
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contenedor de la Descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                currentIncident.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Imagen del incidente si existe, de lo contrario un placeholder
            if (currentIncident.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  currentIncident.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderRadar(),
                ),
              )
            else
              _buildPlaceholderRadar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderRadar() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.radar,
              size: 36,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(height: 8),
            Text(
              'Ubicación en radar...',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
