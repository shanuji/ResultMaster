import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _excelGreen = Color(0xFF217346);
  static const _excelDarkGreen = Color(0xFF185C37);
  static const _sheetBackground = Color(0xFFF3F6F4);
  static const _gridLine = Color(0xFFD9E2DD);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _excelGreen,
      primary: _excelGreen,
      secondary: _excelDarkGreen,
      surface: Colors.white,
      surfaceContainerHighest: _sheetBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _sheetBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _excelGreen,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _gridLine),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _gridLine, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _excelGreen.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _excelGreen,
        unselectedLabelColor: Color(0xFF5F6F67),
        indicatorColor: _excelGreen,
        dividerColor: _gridLine,
      ),
    );
  }
}
