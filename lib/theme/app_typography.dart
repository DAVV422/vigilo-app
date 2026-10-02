import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía del design system (ver DESIGN.md): Hanken Grotesk para
/// titulares (voz de marca), Inter para texto funcional/contenido generado
/// por usuarios, y JetBrains Mono reservado estrictamente para datos
/// técnicos (IDs de reporte, timestamps, coordenadas) — nunca para texto de
/// interfaz general como botones, tabs o chips.
///
/// Antes de esto la app no cargaba ninguna tipografía propia y caía en la
/// fuente del sistema (Roboto/San Francisco), lo que diluye por completo la
/// identidad del design system ya documentado.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    final hanken = GoogleFonts.hankenGroteskTextTheme(base);
    final inter = GoogleFonts.interTextTheme(base);

    return inter.copyWith(
      displayLarge: hanken.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: hanken.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: hanken.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: hanken.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
      ),
      headlineMedium: hanken.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      headlineSmall: hanken.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: hanken.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: hanken.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: hanken.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      // bodyLarge/Medium/Small y labelLarge/Medium/Small quedan en Inter
      // (ya aplicado por GoogleFonts.interTextTheme como base).
    );
  }

  /// Uso explícito en botones primarios/secundarios — DESIGN.md especifica
  /// "Labels set in Hanken Grotesk Bold" para botones, distinto del resto
  /// de la UI funcional que usa Inter.
  static TextStyle buttonLabel({Color? color, double fontSize = 15}) {
    return GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      color: color,
    );
  }

  /// Para IDs de reporte, timestamps y coordenadas — nunca para texto de
  /// interfaz general (ver nota de clase).
  static TextStyle technical({
    double fontSize = 12,
    Color color = AppColors.onSurfaceVariant,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.2,
    );
  }
}
