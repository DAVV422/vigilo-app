import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class MapSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MapSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28), // xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      enabled: false, // UI only for now, logic not required
                      decoration: const InputDecoration(
                        hintText: 'Buscar en el mapa...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.mic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
