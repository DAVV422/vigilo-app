// Autor: Miguel Ángel Gutiérrez Santalla - Contacto: 73663636
import 'package:flutter/material.dart';

/// Design System Color Tokens for Vigilo Mobile App.
/// Strictly defines the official palette. Raw Color instantiations outside this file are forbidden.
class AppColors {
  // Surface tokens
  static const Color surface = Color(0xFFf9f9ff);
  static const Color surfaceDim = Color(0xFFd3daea);
  static const Color surfaceBright = Color(0xFFf9f9ff);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerLow = Color(0xFFf0f3ff);
  static const Color surfaceContainer = Color(0xFFe7eefe);
  static const Color surfaceContainerHigh = Color(0xFFe2e8f8);
  static const Color surfaceContainerHighest = Color(0xFFdce2f3);
  static const Color onSurface = Color(0xFF151c27);
  static const Color onSurfaceVariant = Color(0xFF3e4a3d);
  static const Color inverseSurface = Color(0xFF2a313d);
  static const Color inverseOnSurface = Color(0xFFebf1ff);
  static const Color outline = Color(0xFF6e7b6c);
  static const Color outlineVariant = Color(0xFFbdcaba);
  static const Color surfaceTint = Color(0xFF006e2d);
  static const Color surfaceVariant = Color(0xFFdce2f3);

  // Primary tokens (Recycling / Brand)
  static const Color primary = Color(0xFF006b2c);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color primaryContainer = Color(0xFF00873a);
  static const Color onPrimaryContainer = Color(0xFFf7fff2);
  static const Color inversePrimary = Color(0xFF62df7d);
  static const Color primaryFixed = Color(0xFF7ffc97);
  static const Color primaryFixedDim = Color(0xFF62df7d);
  static const Color onPrimaryFixed = Color(0xFF002109);
  static const Color onPrimaryFixedVariant = Color(0xFF005320);

  // Secondary tokens (Security / Alerts / Insecurity)
  static const Color secondary = Color(0xFFbb0112);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color secondaryContainer = Color(0xFFe02928);
  static const Color onSecondaryContainer = Color(0xFFfffbff);
  static const Color secondaryFixed = Color(0xFFffdad6);
  static const Color secondaryFixedDim = Color(0xFFffb4ab);
  static const Color onSecondaryFixed = Color(0xFF410002);
  static const Color onSecondaryFixedVariant = Color(0xFF93000b);

  // Tertiary tokens (Weeds / Maleza / Nature)
  static const Color tertiary = Color(0xFF825100);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color tertiaryContainer = Color(0xFFa36700);
  static const Color onTertiaryContainer = Color(0xFFfffbff);
  static const Color tertiaryFixed = Color(0xFFffddb8);
  static const Color tertiaryFixedDim = Color(0xFFffb95f);
  static const Color onTertiaryFixed = Color(0xFF2a1700);
  static const Color onTertiaryFixedVariant = Color(0xFF653e00);

  // Error tokens
  static const Color error = Color(0xFFba1a1a);
  static const Color onError = Color(0xFFffffff);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onErrorContainer = Color(0xFF93000a);

  // Background tokens
  static const Color background = Color(0xFFf9f9ff);
  static const Color onBackground = Color(0xFF151c27);

  // Semantic & Legacy aliases for backwards compatibility
  static const Color warning = Color(0xFFE2A000); // Maleza (Amarillo)
  static const Color neutralTrash = Color(0xFF4A4A4A); // Basura (Gris/Negro)
  static const Color ecoGreen = Color(0xFF006e2d); // Reciclaje (Verde oscuro)
  static const Color success = Color(0xFF28a745);
}
