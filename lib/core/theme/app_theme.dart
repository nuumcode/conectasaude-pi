import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  ConectaSaúdePI — Design System
// ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Paleta base ──────────────────────────────────────────
  static const Color bgBase = Color(0xFF061030); // fundo principal
  static const Color bgMid = Color(0xFF0D2B6B); // gradiente radial

  // ── Primárias ────────────────────────────────────────────
  static const Color primary = Color(0xFF4A9FFF); // azul claro (alias blueLt)
  static const Color primaryDeep = Color(0xFF1A72FF); // azul médio
  static const Color accent = Color(0xFF00D4AA); // verde-água (alias greenLt)
  static const Color accentDeep = Color(0xFF00B894); // verde médio

  // ── Aliases semânticos (compat. com código anterior) ─────
  static const Color navyDeep = bgBase;
  static const Color navyMid = bgMid;
  static const Color navyLight = Color(0xFF0A2A6E);
  static const Color blue = primaryDeep;
  static const Color blueLt = primary;
  static const Color blueDark = Color(0xFF0840B0);
  static const Color green = accentDeep;
  static const Color greenLt = accent;

  // ── Gradientes ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDeep, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const RadialGradient bgRadial = RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.5,
    colors: [bgMid, bgBase],
  );

  // ── Textos ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x66FFFFFF);
  static const Color textHint = Color(0x4DFFFFFF);

  // ── Superfícies / bordas ─────────────────────────────────
  static const Color borderDim = Color(0x14FFFFFF);
  static const Color borderMid = Color(0x26FFFFFF);
  static const Color surfaceDim = Color(0x0AFFFFFF);
  static const Color surfaceMid = Color(0x14FFFFFF);

  // ── Status ───────────────────────────────────────────────
  static const Color error = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF00D4AA);
  static const Color warning = Color(0xFFFFB74D);
}

// ─────────────────────────────────────────────────────────────

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
      color: AppColors.textPrimary,
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

  // App name
  static const TextStyle appNameConecta = TextStyle(
      fontFamily: _f,
      fontSize: 28,
      fontWeight: FontWeight.w300,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
      height: 1.1);

  static const TextStyle appNameSaude = TextStyle(
      fontFamily: _f,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      letterSpacing: -0.3,
      height: 1.1);

  static const TextStyle appNamePi = TextStyle(
      fontFamily: _f,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
      letterSpacing: -0.3,
      height: 1.1);
}

// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.bgBase,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDeep,
          secondary: AppColors.accent,
          surface: AppColors.bgMid,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDeep,
            foregroundColor: Colors.white,
            minimumSize:
                const Size(double.infinity, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            textStyle: AppTextStyles.labelLarge,
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize:
                const Size(double.infinity, AppDimensions.buttonHeight),
            side: const BorderSide(color: AppColors.borderMid),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDim,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingMd),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: AppColors.borderDim)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: AppColors.borderDim)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: AppColors.error)),
          hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textHint,
              fontWeight: FontWeight.w400),
          prefixIconColor: AppColors.textTertiary,
          suffixIconColor: AppColors.textTertiary,
        ),
        dividerTheme:
            const DividerThemeData(color: AppColors.borderDim, thickness: 1),
      );

  static void applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
