import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Tema global de Material construido a partir de los tokens documentados
/// en DESIGN.md. Antes de esto cada pantalla definía su propio radio de
/// borde (12, 16, 20, 24px sueltos) y color ad-hoc en vez de usar un tema
/// compartido — esto concentra esas decisiones en un solo lugar para que
/// todo nuevo widget (Card, TextField, ElevatedButton) sea consistente por
/// defecto sin que cada pantalla tenga que repetir la decoración a mano.
///
/// Radios según DESIGN.md ("Shapes — Soft Level 1"): 4px para elementos
/// estándar (botones, inputs), 8px para contenedores (cards, modales).
class AppTheme {
  AppTheme._();

  static const double radiusStandard = 4;
  static const double radiusContainer = 8;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(base.textTheme),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusContainer),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.outline,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppTypography.buttonLabel(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppTypography.buttonLabel(color: AppColors.onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.buttonLabel(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.outline),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.onSurface, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: AppColors.onPrimary, fontSize: 13),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 32,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusContainer),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: TextStyle(color: AppColors.inverseOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
      ),
    );
  }
}
