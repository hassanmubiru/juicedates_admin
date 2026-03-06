import 'package:flutter/material.dart';

// ── Brand palette ─────────────────────────────────────────────────────────
const kTangerine = Color(0xFFFF6B35);
const kDarkBg    = Color(0xFF0F1117);
const kSidebar   = Color(0xFF1A1D27);
const kCard      = Color(0xFF22263A);
const kBorder    = Color(0xFF2C3050);
const kSuccess   = Color(0xFF4CAF50);
const kWarning   = Color(0xFFFFC107);
const kDanger    = Color(0xFFEF5350);
const kMuted     = Color(0xFF8891B2);

ThemeData adminTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: kTangerine,
      surface: kCard,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: kDarkBg,
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSidebar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kTangerine, width: 1.5),
      ),
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kTangerine,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      titleLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: Colors.white, fontSize: 15),
      bodyMedium: TextStyle(color: kMuted),
      labelSmall: TextStyle(color: kMuted, fontSize: 11),
    ),
    iconTheme: const IconThemeData(color: kMuted),
    dividerTheme:
        const DividerThemeData(color: kBorder, space: 1, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: kSidebar,
      side: const BorderSide(color: kBorder),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(kBorder),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(kSidebar),
      dataRowColor: WidgetStatePropertyAll(kCard),
      headingTextStyle: TextStyle(color: kMuted, fontSize: 12),
      dataTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      dividerThickness: 1,
    ),
  );
}
