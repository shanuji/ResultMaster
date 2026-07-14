import 'package:flutter/material.dart';

class ExcelTheme {
  static const primaryGreen = Color(0xFF217346);
  static const headerGreen = Color(0xFFE2F0D9);
  static const gridLine = Color(0xFFD9E2D0);
  static const alternateRow = Color(0xFFF7FBF4);

  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: primaryGreen, foregroundColor: Colors.white, centerTitle: false),
        dataTableTheme: const DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(headerGreen),
          dividerThickness: 0.7,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 48,
        ),
        useMaterial3: true,
      );
}
