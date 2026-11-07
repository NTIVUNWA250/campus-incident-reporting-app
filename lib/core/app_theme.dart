import 'package:flutter/material.dart';

const brand = Color(0xFF7041F5);
const ink = Color(0xFF191B39);
const muted = Color(0xFF777B96);
const canvas = Color(0xFFF8F9FF);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: brand, surface: Colors.white),
  scaffoldBackgroundColor: canvas,
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: ink,
    displayColor: ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    centerTitle: true,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E3F1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E3F1)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brand,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  chipTheme: const ChipThemeData(
    side: BorderSide.none,
    selectedColor: Color(0xFFEDE6FF),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Color(0xFFEDE6FF),
    labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
  ),
);

IconData categoryIcon(String name) => switch (name) {
  'water' => Icons.water_drop_outlined,
  'electricity' => Icons.bolt_outlined,
  'furniture' => Icons.chair_outlined,
  'safety' => Icons.shield_outlined,
  'sanitation' => Icons.delete_outline,
  _ => Icons.apartment_outlined,
};

String dateLabel(DateTime? date) {
  if (date == null) return 'Saving...';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
