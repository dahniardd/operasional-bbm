import 'package:flutter/material.dart';

import 'pln_colors.dart';

/// Token desain untuk dashboard Android.
///
/// Palet lama tetap dipakai layar lain; token ini menjadi sumber nilai
/// semantik untuk komponen dashboard yang dimigrasikan.
class AppTokens {
  AppTokens._();

  // Brand
  static const Color brand = PlnColors.primaryBlue;
  static const Color brandDark = PlnColors.darkNavy;
  static const Color accent = PlnColors.accentYellow;
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
  );

  // On brand (header biru)
  static const Color onBrand = Colors.white;
  static const Color onBrandMuted = Color(0xC7FFFFFF);
  static const Color onBrandFaint = Color(0x24FFFFFF);
  static const Color onBrandBorder = Color(0x2EFFFFFF);
  static const Color onBrandOverlay = Color(0x0FFFFFFF);
  static const Color onBrandAccent = Color(0x1AFFFFFF);
  static const Color onBrandSoft = Color(0x4DFFFFFF);

  // Surface & teks
  static const Color background = PlnColors.background;
  static const Color surface = PlnColors.surface;
  static const Color textPrimary = PlnColors.textPrimary;
  static const Color textSecondary = PlnColors.textSecondary;
  static const Color border = PlnColors.border;

  // Status
  static const Color success = PlnColors.success;
  static const Color warning = PlnColors.warning;
  static const Color danger = PlnColors.danger;
  static const Color warningText = Color(0xFFB45309);

  // Spacing
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusCard = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // Ukuran & aksesibilitas
  static const double minTapTarget = 48;
  static const double minFontSize = 12;
  static const double contentMaxWidth = 760;

  // Tipografi
  static const double fontCaption = 12;
  static const double fontBody = 13;
  static const double fontTitle = 16;
  static const double fontHeading = 18;

  // Skeleton
  static const Color skeletonBase = PlnColors.lightGray;
  static const Color skeletonBorder = PlnColors.border;
}
