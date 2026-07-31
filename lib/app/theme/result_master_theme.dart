import 'package:flutter/material.dart';

class ResultMasterTheme {
  const ResultMasterTheme._();

  static const Color primary = Color(0xFF0A8D82);
  static const Color primaryDark = Color(0xFF066D66);
  static const Color primaryLight = Color(0xFFE8FBF8);
  static const Color accent = Color(0xFF21D4B7);

  static const Color surface = Color(0xFFF5F8FA);
  static const Color card = Colors.white;
  static const Color gridLine = Color(0xFFDDE8E5);
  static const Color excelGreen = primary;
  static const Color excelDarkGreen = primaryDark;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: const Color(0xFFE53935),
    );

    return _theme(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: primaryLight,
      surface: const Color(0xFF0D1F1D),
      error: const Color(0xFFFFB4AB),
    );

    return _theme(scheme, Brightness.dark);
  }

  static ThemeData _theme(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? surface : const Color(0xFF071513),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false, backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      cardTheme: CardTheme(
        elevation: 0,
        color: isLight ? card : const Color(0xFF102522),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: scheme.primary.withOpacity(.08))),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary.withOpacity(.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), side: BorderSide(color: scheme.primary.withOpacity(.28)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), foregroundColor: scheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF102522),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary.withOpacity(.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      dividerTheme: DividerThemeData(color: isLight ? gridLine : Colors.white12, thickness: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8)),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
    );
  }
}
