// lib/domain/enums/alert_category.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

enum AlertCategory {
  seguridad,
  reciclaje,
  maleza;

  Color get backgroundColor {
    switch (this) {
      case AlertCategory.seguridad:
        return AppColors.errorContainer;
      case AlertCategory.reciclaje:
        return AppColors.primaryFixed;
      case AlertCategory.maleza:
        return AppColors.tertiaryFixed;
    }
  }

  Color get textColor {
    switch (this) {
      case AlertCategory.seguridad:
        return AppColors.onErrorContainer;
      case AlertCategory.reciclaje:
        return AppColors.onPrimaryFixedVariant;
      case AlertCategory.maleza:
        return AppColors.onTertiaryFixedVariant;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertCategory.seguridad:
        return AppIcons.security;
      case AlertCategory.reciclaje:
        return AppIcons.recycling;
      case AlertCategory.maleza:
        return AppIcons.weeds;
    }
  }

  String get displayName {
    switch (this) {
      case AlertCategory.seguridad:
        return 'Seguridad';
      case AlertCategory.reciclaje:
        return 'Reciclaje';
      case AlertCategory.maleza:
        return 'Maleza';
    }
  }
}
