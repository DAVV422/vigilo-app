
import 'package:flutter/material.dart';
import '../domain/entities/incident.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Atomic Action Button widget for list items, card actions, and interactions (e.g. "Ver").
/// Fully parametric and themed exclusively via AppColors design tokens.
class AppActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
  final double iconSize;

  const AppActionButton({
    super.key,
    this.label = 'Ver',
    this.icon = AppIcons.openInNew,
    this.onTap,
    this.backgroundColor = AppColors.surfaceContainerHigh,
    this.foregroundColor = AppColors.primary,
    this.fontSize = 12.0,
    this.iconSize = 12.0,
  });

  /// Factory constructor to create a themed action button according to the IncidentType.
  factory AppActionButton.fromIncidentType({
    Key? key,
    required IncidentType type,
    String label = 'Ver',
    IconData icon = AppIcons.openInNew,
    VoidCallback? onTap,
  }) {
    Color bg;
    Color fg;

    switch (type) {
      case IncidentType.insecurity:
        bg = AppColors.errorContainer;
        fg = AppColors.onErrorContainer;
        break;
      case IncidentType.recycling:
        bg = AppColors.primaryFixed;
        fg = AppColors.onPrimaryFixedVariant;
        break;
      case IncidentType.weeds:
        bg = AppColors.tertiaryFixed;
        fg = AppColors.onTertiaryFixedVariant;
        break;
      case IncidentType.trash:
        bg = AppColors.surfaceContainerHighest;
        fg = AppColors.onSurfaceVariant;
        break;
    }

    return AppActionButton(
      key: key,
      label: label,
      icon: icon,
      onTap: onTap,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                size: iconSize,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
