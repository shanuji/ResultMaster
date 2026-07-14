import 'package:flutter/material.dart';

class ResultMasterTheme {
  static const Color excelGreen = Color(0xFF217346);
  static const Color excelDarkGreen = Color(0xFF185C37);
  static const Color gridLine = Color(0xFFD0D7DE);
  static const Color sheetBackground = Color(0xFFF8FAF8);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: excelGreen,
      primary: excelGreen,
      secondary: const Color(0xFF107C41),
      surface: sheetBackground,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: sheetBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: excelGreen,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: excelGreen,
      brightness: Brightness.dark,
    );
    return _base(scheme).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: excelDarkGreen,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: gridLine.withValues(alpha: 0.8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: excelGreen.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
