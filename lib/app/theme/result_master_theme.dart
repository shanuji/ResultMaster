import 'package:flutter/material.dart';

class ResultMasterTheme {
  static const Color primary = Color(0xFF0A8D82);
  static const Color primaryDark = Color(0xFF066D66);
  static const Color primaryLight = Color(0xFFE8FBF8);

  static const Color surface = Color(0xFFF5F8FA);
  static const Color card = Colors.white;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: const Color(0xFF1CB5A3),
      surface: surface,
      error: const Color(0xFFE53935),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,

      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(
            color: primary.withOpacity(.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: primary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: primary,
        secondarySelectedColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
        ),
      );
    );
  }
}
