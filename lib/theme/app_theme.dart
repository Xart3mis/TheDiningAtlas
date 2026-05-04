import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFF5F0E8);
  static const parchment = Color(0xFFEDE8DC);
  static const ink = Color(0xFF1C1C1A);
  static const terracotta = Color(0xFFCC4A1E);
  static const teal = Color(0xFF2E5B52);
  static const gold = Color(0xFFB8962E);
  static const warmGrey = Color(0xFF8C8680);
  static const lightGrey = Color(0xFFD9D4CC);
  static const white = Color(0xFFFAF8F4);
  static const sageGreen = Color(0xFF5C7A6B);
  static const dustyBlue = Color(0xFF7090A0);
  static const warmTan = Color(0xFFC4A96A);
  static const softRed = Color(0xFFB85C4A);

  // Tile placeholder colors matching design
  static const tile1 = Color(0xFF7090A0); // dusty blue
  static const tile2 = Color(0xFFB8962E); // gold
  static const tile3 = Color(0xFF5C7A6B); // sage
  static const tile4 = Color(0xFFB85C4A); // soft red
  static const tile5 = Color(0xFF8C7B6A); // warm brown
}

class AppTextStyles {
  static TextStyle display(BuildContext context) =>
      GoogleFonts.fraunces(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.15);

  static TextStyle headline(BuildContext context) =>
      GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.2);

  static TextStyle title(BuildContext context) =>
      GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink);

  static TextStyle titleItalic(BuildContext context) =>
      GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: AppColors.terracotta);

  static TextStyle body(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, color: AppColors.ink, height: 1.5);

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, color: AppColors.warmGrey, height: 1.4);

  static TextStyle label(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmGrey, letterSpacing: 1.2);

  static TextStyle mono(BuildContext context) =>
      GoogleFonts.dmMono(fontSize: 11, color: AppColors.warmGrey, letterSpacing: 0.5);

  static TextStyle accent(BuildContext context) =>
      GoogleFonts.fraunces(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.terracotta);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.light(
      primary: AppColors.terracotta,
      secondary: AppColors.teal,
      surface: AppColors.cream,
      background: AppColors.cream,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.terracotta,
      unselectedItemColor: AppColors.warmGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.lightGrey,
  );
}
