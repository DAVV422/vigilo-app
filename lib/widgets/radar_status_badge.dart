
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Enum representing the state of the radar indicator.
enum RadarState {
  loading,
  inRange,
  outOfRange,
  inactive,
}

/// Atomic Status & Radar Badge component.
/// Provides visual feedback for distance radar detection and loading state.
class RadarStatusBadge extends StatelessWidget {
  final RadarState state;
  final String? customLabel;
  final double? distanceInMeters;

  const RadarStatusBadge({
    super.key,
    required this.state,
    this.customLabel,
    this.distanceInMeters,
  });

  /// Factory for loading state ("Cargando radar...").
  const factory RadarStatusBadge.loading({Key? key}) = _RadarStatusBadgeLoading;

  /// Factory for inactive radar state ("Radar inactivo").
  const factory RadarStatusBadge.inactive({Key? key}) = _RadarStatusBadgeInactive;

  /// Factory to automatically determine state from distance and loading status.
  factory RadarStatusBadge.fromDistance({
    Key? key,
    required double? distanceInMeters,
    required bool isLoading,
    double rangeThresholdMeters = 200.0,
  }) {
    if (isLoading) {
      return RadarStatusBadge.loading(key: key);
    }
    if (distanceInMeters == null) {
      return RadarStatusBadge.inactive(key: key);
    }

    final isInRange = distanceInMeters <= rangeThresholdMeters;
    return RadarStatusBadge(
      key: key,
      state: isInRange ? RadarState.inRange : RadarState.outOfRange,
      distanceInMeters: distanceInMeters,
    );
  }

  Color get _backgroundColor {
    switch (state) {
      case RadarState.loading:
      case RadarState.inactive:
      case RadarState.outOfRange:
        return AppColors.surfaceContainerHighest;
      case RadarState.inRange:
        return AppColors.primaryFixed;
    }
  }

  Color get _foregroundColor {
    switch (state) {
      case RadarState.loading:
      case RadarState.inactive:
        return AppColors.outline;
      case RadarState.outOfRange:
        return AppColors.onSurfaceVariant;
      case RadarState.inRange:
        return AppColors.onPrimaryFixedVariant;
    }
  }

  IconData get _icon {
    switch (state) {
      case RadarState.loading:
      case RadarState.inactive:
      case RadarState.inRange:
        return AppIcons.radar;
      case RadarState.outOfRange:
        return AppIcons.locked;
    }
  }

  String get _label {
    if (customLabel != null) return customLabel!;

    switch (state) {
      case RadarState.loading:
        return 'Cargando radar...';
      case RadarState.inactive:
        return 'Radar inactivo';
      case RadarState.inRange:
      case RadarState.outOfRange:
        if (distanceInMeters == null) return '--';
        if (distanceInMeters! < 1000) {
          return '${distanceInMeters!.toInt()}m';
        } else {
          return '${(distanceInMeters! / 1000).toStringAsFixed(1)}km';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 12,
            color: _foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarStatusBadgeLoading extends RadarStatusBadge {
  const _RadarStatusBadgeLoading({super.key}) : super(state: RadarState.loading);
}

class _RadarStatusBadgeInactive extends RadarStatusBadge {
  const _RadarStatusBadgeInactive({super.key}) : super(state: RadarState.inactive);
}
