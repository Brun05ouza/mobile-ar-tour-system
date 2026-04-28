import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual e tema — produto final orientado a visitantes.
abstract final class AppBrand {
  static const String name = 'AR Tour';
  static const String tagline = 'Experiências guiadas em realidade aumentada';
  static const String footerHint =
      'Compatível com dispositivos certificados para ARCore';
}

abstract final class AppGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0C10),
      Color(0xFF12151C),
      Color(0xFF0E1218),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient heroAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D3A4D),
      Color(0xFF1A2230),
    ],
  );

  static const LinearGradient goldShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4B896),
      Color(0xFFB8956E),
      Color(0xFF9A7654),
    ],
  );
}

abstract final class AppColors {
  static const Color bgDeep = Color(0xFF0A0C10);
  static const Color surface = Color(0xFF161B24);
  static const Color surfaceElevated = Color(0xFF1E2533);
  static const Color borderSubtle = Color(0x26FFFFFF);
  static const Color accent = Color(0xFFC9A87C);
  static const Color accentMuted = Color(0xFF8B7355);
  static const Color teal = Color(0xFF4FD1C5);
  static const Color indigo = Color(0xFF7C8EDA);
  static const Color textPrimary = Color(0xFFF4F1EC);
  static const Color textSecondary = Color(0xFFB8B4AB);
  static const Color textHint = Color(0xFF6B7280);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        onPrimary: const Color(0xFF1A1510),
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderSubtle,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDeep,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF1A1510),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
      ),
    );
  }

  /// Título editorial principal (home, onboarding).
  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      );

  static TextStyle titleSection(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        color: AppColors.accent,
      );

  static TextStyle bodyMuted(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15,
        height: 1.55,
        color: AppColors.textSecondary,
      );
}

/// Fundo em gradiente — use como [Scaffold.body] para consistência visual.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: child,
    );
  }
}
