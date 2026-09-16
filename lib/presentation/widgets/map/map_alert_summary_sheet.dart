import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/incident.dart';
import '../../../../domain/enums/alert_category.dart';
import '../../screens/alerts/alert_detail_screen.dart';

class MapAlertSummarySheet extends StatelessWidget {
  final Incident incident;
  final String distanceText;

  const MapAlertSummarySheet({
    super.key,
    required this.incident,
    required this.distanceText,
  });

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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // xl radius
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del Resumen
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _category.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _category.icon,
                  color: _category.textColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cuerpo
          Text(
            incident.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'A $distanceText de ti',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Acción
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertDetailScreen(incident: incident),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Ver detalle completo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
