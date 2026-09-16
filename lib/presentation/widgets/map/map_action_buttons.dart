import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class MapActionButtons extends StatelessWidget {
  final VoidCallback onMyLocationPressed;
  final VoidCallback onLayersPressed;

  const MapActionButtons({
    super.key,
    required this.onMyLocationPressed,
    required this.onLayersPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 80, // Below the search bar
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'layers_filter_btn',
            backgroundColor: AppColors.surfaceContainerLowest,
            foregroundColor: AppColors.onSurfaceVariant,
            elevation: 4,
            onPressed: onLayersPressed,
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            mini: true,
            heroTag: 'my_location_btn',
            backgroundColor: AppColors.surfaceContainerLowest,
            foregroundColor: AppColors.primary,
            elevation: 4,
            onPressed: onMyLocationPressed,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
