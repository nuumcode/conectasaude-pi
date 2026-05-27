import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  ConectaSaúdePI — Design System (LIGHT THEME)
// ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Paleta base (Claro) ─────────────────────────
  static const Color bgBase = Color(0xFFFFFFFF); // Fundo principal branco puro
  static const Color bgMid = Color(0xFFFFFFFF);  // superfícies

  // ── Primárias (Azul ConectaSaúdePI - Baseado na Index) ─────────────────────────
  static const Color primary = Color(0xFF1A72FF);     // Azul principal vibrante
  static const Color primaryDeep = Color(0xFF0D47A1); // azul escuro
  static const Color accent = Color(0xFF10B981);      // verde sucesso
  static const Color accentDeep = Color(0xFF059669);

  // ── Aliases para compatibilidade ──────────────────────────
  static const Color navyDeep = Color(0xFF061030); // Usado em áreas específicas dark
  static const Color blue = primary;
  static const Color blueLt = Color(0xFFE0E7FF);

  // ── Gradientes ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF4A9FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Textos ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);   // quase preto
  static const Color textSecondary = Color(0xFF64748B); // cinza médio
  static const Color textTertiary = Color(0xFF94A3B8);  // cinza claro
  static const Color textHint = Color(0xFFCBD5E1);

  // ── Superfícies / bordas ─────────────────────────────────
  static const Color borderDim = Color(0xFFE2E8F0);
  static const Color borderMid = Color(0xFFCBD5E1);
  static const Color surfaceDim = Color(0xFFF1F5F9);
  static const Color surfaceMid = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color greenLt = accent; // Alias for compatibility
}

class AppTextStyles {
  AppTextStyles._();
  static const String _f = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
      fontFamily: _f,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1.0,
      height: 1.0);

  static const TextStyle headlineLarge = TextStyle(
      fontFamily: _f,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2);

  static const TextStyle headlineMedium = TextStyle(
      fontFamily: _f,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);

  static const TextStyle bodyLarge = TextStyle(
      fontFamily: _f,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.6);

  static const TextStyle bodyMedium = TextStyle(
      fontFamily: _f,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.5);

  static const TextStyle labelLarge = TextStyle(
      fontFamily: _f,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.3);

  static const TextStyle labelSmall = TextStyle(
      fontFamily: _f,
      fontSize: 9,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiary,
      letterSpacing: 1.8);

  static const TextStyle caption = TextStyle(
      fontFamily: _f,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary);
}

class AppDimensions {
  AppDimensions._();
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;
  static const double inputHeight = 52.0;
  static const double buttonHeight = 52.0;
  static const double iconSizeMd = 19.0;
  static const double iconSizeLg = 22.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.bgBase,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: Colors.white,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            side: const BorderSide(color: AppColors.borderDim),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderDim)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderDim)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error)),
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textTertiary),
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          prefixIconColor: AppColors.textSecondary,
        ),
      );

  static void applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgBase,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
