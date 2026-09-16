// lib/presentation/widgets/profile/medals_gallery.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';

class MedalItem {
  final String title;
  final IconData icon;
  final bool isActive;

  const MedalItem({
    required this.title,
    required this.icon,
    required this.isActive,
  });
}

class MedalsGallery extends StatelessWidget {
  final List<MedalItem> medals;

  const MedalsGallery({
    Key? key,
    this.medals = const [
      MedalItem(
        title: 'Guardián',
        icon: AppIcons.securityShield,
        isActive: true,
      ),
      MedalItem(
        title: 'Rastreador',
        icon: AppIcons.search,
        isActive: true,
      ),
      MedalItem(
        title: 'Rápido',
        icon: Icons.bolt,
        isActive: true,
      ),
      MedalItem(
        title: 'Eco Pionero',
        icon: AppIcons.recycling,
        isActive: false,
      ),
      MedalItem(
        title: 'Nocturno',
        icon: Icons.nightlight_round,
        isActive: false,
      ),
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: medals.length,
        itemBuilder: (context, index) {
          final medal = medals[index];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
              border: medal.isActive
                  ? Border.all(
                      color: AppColors.tertiaryFixedDim,
                      width: 1.5,
                    )
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
              boxShadow: medal.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.tertiaryFixedDim.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: medal.isActive
                      ? AppColors.tertiaryFixed
                      : AppColors.surfaceVariant.withValues(alpha: 0.5),
                  child: Icon(
                    medal.icon,
                    size: 24,
                    color: medal.isActive
                        ? AppColors.tertiary
                        : AppColors.outlineVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  medal.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: medal.isActive
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
