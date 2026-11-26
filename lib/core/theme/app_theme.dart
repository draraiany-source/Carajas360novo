import 'package:flutter/material.dart';
import 'app_colors.dart';

TextStyle sans({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

abstract class AppDecorations {
  static BoxDecoration card(
          {double r = 20, Color? color, bool elevated = true, BuildContext? context}) {
    final isDark = context != null &&
        Theme.of(context).brightness == Brightness.dark;
    final bg = color ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: border.withValues(alpha: 0.65)),
      boxShadow: elevated
          ? [
              BoxShadow(
                  color: AppColors.navy.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10)),
              BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ]
          : [],
    );
  }

  static BoxDecoration gradient(Gradient g, {double r = 20}) =>
      BoxDecoration(gradient: g, borderRadius: BorderRadius.circular(r));

  static BoxDecoration headerGradient(Gradient g, {double r = 28}) =>
      BoxDecoration(
          gradient: g,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(r), bottomRight: Radius.circular(r)));

  static BoxDecoration outlined({double r = 16, Color? color}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: color ?? AppColors.border));

  static BoxDecoration softPanel({double r = 24}) => BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 18)),
        ],
      );
}

class AppTheme {
  static TextTheme _textTheme(Color high, Color med, Color low) {
    final base = ThemeData(fontFamily: 'PlusJakartaSans').textTheme;
    return base.copyWith(
      displayLarge: sans(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: high,
          letterSpacing: -1.2,
          height: 1.1),
      headlineLarge: sans(
          fontSize: 26, fontWeight: FontWeight.w800, color: high, height: 1.15),
      headlineMedium: sans(
          fontSize: 22, fontWeight: FontWeight.w700, color: high),
      headlineSmall: sans(
          fontSize: 18, fontWeight: FontWeight.w700, color: high),
      titleLarge: sans(
          fontSize: 16, fontWeight: FontWeight.w700, color: high),
      titleMedium: sans(
          fontSize: 14, fontWeight: FontWeight.w600, color: high),
      bodyLarge: sans(
          fontSize: 15, fontWeight: FontWeight.w400, color: high, height: 1.55),
      bodyMedium: sans(
          fontSize: 13, fontWeight: FontWeight.w400, color: med, height: 1.5),
      bodySmall: sans(
          fontSize: 12, fontWeight: FontWeight.w400, color: low, height: 1.4),
      labelLarge: sans(
          fontSize: 14, fontWeight: FontWeight.w700, color: high),
    );
  }

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, fontFamily: 'PlusJakartaSans');
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(
          AppColors.textDark, AppColors.textMedium, AppColors.textLight),
      appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          centerTitle: true,
          titleTextStyle: sans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white),
          iconTheme: const IconThemeData(color: AppColors.white)),
      cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: sans(
                  fontSize: 15, fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border, width: 1.4),
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: sans(
            fontSize: 14, color: AppColors.textHint),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 0),
      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          showDragHandle: true),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        labelStyle: sans(
            fontWeight: FontWeight.w700, fontSize: 13),
        indicator: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'PlusJakartaSans');
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          surface: AppColors.darkSurface,
          error: AppColors.error),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(
          AppColors.darkTextHigh, AppColors.darkTextMed, AppColors.darkTextLow),
      appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextHigh,
          centerTitle: true,
          titleTextStyle: sans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextHigh)),
      cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: sans(
                  fontSize: 15, fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkTextHigh,
              side: const BorderSide(color: AppColors.darkBorder, width: 1.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 1.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.darkTextLow,
          type: BottomNavigationBarType.fixed,
          elevation: 0),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.darkTextLow,
        labelStyle: sans(
            fontWeight: FontWeight.w700, fontSize: 13),
        dividerColor: Colors.transparent,
      ),
    );
  }
}
