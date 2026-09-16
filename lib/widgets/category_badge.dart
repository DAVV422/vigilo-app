
import 'package:flutter/material.dart';
import '../domain/entities/incident.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Enum representing the visual category type for design system badges.
enum CategoryBadgeType {
  security,
  recycling,
  weeds,
  trash;

  /// Helper to convert domain IncidentType to visual CategoryBadgeType.
  static CategoryBadgeType fromIncidentType(IncidentType type) {
    switch (type) {
      case IncidentType.insecurity:
        return CategoryBadgeType.security;
      case IncidentType.recycling:
        return CategoryBadgeType.recycling;
      case IncidentType.weeds:
        return CategoryBadgeType.weeds;
      case IncidentType.trash:
        return CategoryBadgeType.trash;
    }
  }
}

/// Size variant for the category badge.
enum CategoryBadgeSize {
  compact,
  standard,
}

/// Atomic Category Badge widget conforming strictly to the Vigilo Design System.
/// Uses exclusively design tokens from AppColors and icons from AppIcons.
class CategoryBadge extends StatelessWidget {
  final CategoryBadgeType category;
  final String? customLabel;
  final bool showIcon;
  final CategoryBadgeSize size;
  final VoidCallback? onTap;

  const CategoryBadge({
    super.key,
    required this.category,
    this.customLabel,
    this.showIcon = false,
    this.size = CategoryBadgeSize.standard,
    this.onTap,
  });

  /// Factory constructor to create a badge directly from domain [IncidentType].
  factory CategoryBadge.fromIncidentType({
    Key? key,
    required IncidentType type,
    String? customLabel,
    bool showIcon = false,
    CategoryBadgeSize size = CategoryBadgeSize.standard,
    VoidCallback? onTap,
  }) {
    return CategoryBadge(
      key: key,
      category: CategoryBadgeType.fromIncidentType(type),
      customLabel: customLabel,
      showIcon: showIcon,
      size: size,
      onTap: onTap,
    );
  }

  Color get _backgroundColor {
    switch (category) {
      case CategoryBadgeType.security:
        return AppColors.errorContainer;
      case CategoryBadgeType.recycling:
        return AppColors.primaryFixed;
      case CategoryBadgeType.weeds:
        return AppColors.tertiaryFixed;
      case CategoryBadgeType.trash:
        return AppColors.surfaceContainerHighest;
    }
  }

  Color get _foregroundColor {
    switch (category) {
      case CategoryBadgeType.security:
        return AppColors.onErrorContainer;
      case CategoryBadgeType.recycling:
        return AppColors.onPrimaryFixedVariant;
      case CategoryBadgeType.weeds:
        return AppColors.onTertiaryFixedVariant;
      case CategoryBadgeType.trash:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData get _icon {
    switch (category) {
      case CategoryBadgeType.security:
        return AppIcons.securityShield;
      case CategoryBadgeType.recycling:
        return AppIcons.recycling;
      case CategoryBadgeType.weeds:
        return AppIcons.weeds;
      case CategoryBadgeType.trash:
        return AppIcons.trash;
    }
  }

  String get _defaultLabel {
    switch (category) {
      case CategoryBadgeType.security:
        return 'Seguridad';
      case CategoryBadgeType.recycling:
        return 'Reciclaje';
      case CategoryBadgeType.weeds:
        return 'Maleza';
      case CategoryBadgeType.trash:
        return 'Basura';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = size == CategoryBadgeSize.compact;
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final fontSize = isCompact ? 10.0 : 11.0;
    final iconSize = isCompact ? 12.0 : 14.0;

    final badgeContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              size: iconSize,
              color: _foregroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            customLabel ?? _defaultLabel,
            style: TextStyle(
              color: _foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
