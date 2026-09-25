import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../domain/entities/incident.dart';
import '../../../../theme/app_colors.dart';

class ValidationCard extends StatelessWidget {
  final Incident incident;
  final LatLng currentLocation;
  final VoidCallback onStillThere;
  final VoidCallback onResolved;

  const ValidationCard({
    super.key,
    required this.incident,
    required this.currentLocation,
    required this.onStillThere,
    required this.onResolved,
  });

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else {
      return 'Hace ${diff.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      incident.location.latitude,
      incident.location.longitude,
    );

    Color getCategoryColor() {
      switch (incident.type) {
        case IncidentType.insecurity: return AppColors.errorContainer;
        case IncidentType.trash: return AppColors.tertiary; // Brown for trash based on image
        case IncidentType.weeds: return AppColors.tertiaryContainer;
        case IncidentType.recycling: return AppColors.primaryContainer;
      }
    }

    Color getCategoryIconColor() {
      switch (incident.type) {
        case IncidentType.insecurity: return AppColors.error;
        case IncidentType.trash: return AppColors.onTertiary;
        case IncidentType.weeds: return AppColors.onTertiaryContainer;
        case IncidentType.recycling: return AppColors.onPrimaryContainer;
      }
    }

    IconData getCategoryIcon() {
      switch (incident.type) {
        case IncidentType.insecurity: return Icons.error_outline;
        case IncidentType.trash: return Icons.delete_outline;
        case IncidentType.weeds: return Icons.location_on;
        case IncidentType.recycling: return Icons.recycling;
      }
    }

    // Default mock titles if incident title is empty
    String title = incident.title.isNotEmpty ? incident.title : 'Av. Central 123';
    String addressText = '$title • A ${distance.toInt()}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: getCategoryColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getCategoryIcon(),
                  color: getCategoryIconColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          addressText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTimeAgo(incident.reportedAt),
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onStillThere,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Sigue ahí',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onResolved,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.onPrimary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Solucionado',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
