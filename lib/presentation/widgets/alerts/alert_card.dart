// lib/presentation/widgets/alerts/alert_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/incident.dart';
import '../../../domain/enums/alert_category.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';

class AlertCard extends StatelessWidget {
  final Incident incident;
  final bool isValidatedByMe;
  final VoidCallback? onValidateTap;
  final VoidCallback? onViewTap;

  const AlertCard({
    Key? key,
    required this.incident,
    required this.isValidatedByMe,
    this.onValidateTap,
    this.onViewTap,
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
    return DateFormat("dd MMM, hh:mm a").format(incident.reportedAt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _category.backgroundColor,
                width: 6.0,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _category.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      _category.icon,
                      color: _category.textColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              AppIcons.person,
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Usuario', // Asumiendo que aún no se resuelve el nombre
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _category.backgroundColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _category.displayName,
                      style: TextStyle(
                        color: _category.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // DESCRIPTION
              Text(
                incident.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // META ROW (Date and Validations)
              Row(
                children: [
                  const Icon(
                    AppIcons.time,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    AppIcons.thumbUp,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${incident.validatorsIds.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // DIVIDER
              const Divider(color: AppColors.surfaceContainerHigh, height: 1),
              const SizedBox(height: 16),
              
              // ACTION BUTTONS
              Row(
                children: [
                  // Radar Button
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.radar, size: 14, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 6),
                          Text(
                            'Cargando\nradar...',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.1,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Validar Button
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: onValidateTap,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isValidatedByMe
                              ? AppColors.primaryFixed.withValues(alpha: 0.5)
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isValidatedByMe ? AppIcons.thumbUpFilled : AppIcons.thumbUp,
                              size: 16,
                              color: isValidatedByMe ? AppColors.onPrimaryFixedVariant : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isValidatedByMe ? '${incident.validatorsIds.length} val.' : 'Validar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isValidatedByMe ? AppColors.onPrimaryFixedVariant : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Ver Button
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: onViewTap,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _category.backgroundColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ver',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _category.textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              AppIcons.openInNew,
                              size: 14,
                              color: _category.textColor,
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
        ),
      ),
    );
  }
}
