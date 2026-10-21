import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography from the Figma style guide (DM Sans).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headline1 => GoogleFonts.dmSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 46 / 36,
        letterSpacing: -1.6,
        color: AppColors.dark,
      );

  /// Big grey intro line under screen titles ("Welcome back, you've been missed!").
  static TextStyle get subtitle => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 34 / 24,
        letterSpacing: -0.6,
        color: AppColors.textSubtle,
      );

  static TextStyle get navTitle => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 28 / 18,
        letterSpacing: -0.4,
        color: AppColors.dark,
      );

  static TextStyle get headline6 => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 24 / 14,
        letterSpacing: -0.3,
        color: AppColors.dark,
      );

  static TextStyle get paragraph => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 26 / 16,
        letterSpacing: -0.36,
        color: AppColors.textBody,
      );

  static TextStyle get input => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: -0.3,
        color: AppColors.dark,
      );

  static TextStyle get label => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: AppColors.label,
      );

  static TextStyle get small => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: -0.2,
        color: AppColors.textBody,
      );

  static TextStyle get smallBold => small.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: AppColors.dark,
      );

  static TextStyle get button => headline6.copyWith(color: AppColors.white);
}
