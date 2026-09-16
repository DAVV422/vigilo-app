
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Atomic Validation / Counter Badge widget.
/// Displays validator count or upvote metrics using strictly design system tokens.
class ValidationBadge extends StatelessWidget {
  final int count;
  final String? customLabel;
  final VoidCallback? onTap;

  const ValidationBadge({
    super.key,
    required this.count,
    this.customLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? '$count val.';

    final badgeContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.thumbUp,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
