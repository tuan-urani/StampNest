import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class StampverseTextStyles {
  StampverseTextStyles._();

  static TextStyle _withoutDecoration(TextStyle style) {
    return style.copyWith(
      decoration: TextDecoration.none,
      decorationColor: AppColors.transparent,
    );
  }

  static TextStyle heroTitle({Color color = AppColors.stampverseHeadingText}) {
    return _withoutDecoration(
      GoogleFonts.mynerve(
        textStyle: AppStyles.h4(color: color, fontWeight: FontWeight.w700),
      ).copyWith(fontSize: 22, height: 1.2, letterSpacing: 0.2),
    );
  }

  static TextStyle sectionTitle({
    Color color = AppColors.stampversePrimaryText,
  }) {
    return _withoutDecoration(
      GoogleFonts.crimsonPro(
        textStyle: AppStyles.h4(color: color, fontWeight: FontWeight.w700),
      ).copyWith(fontSize: 22, height: 1.2, letterSpacing: 1.1),
    );
  }

  static TextStyle body({
    Color color = AppColors.stampverseMutedText,
    FontWeight fontWeight = FontWeight.w500,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return _withoutDecoration(
      GoogleFonts.mynerve(
        textStyle: AppStyles.bodyLarge(color: color, fontWeight: fontWeight),
      ).copyWith(fontSize: 16, height: 1.35, fontStyle: fontStyle),
    );
  }

  static TextStyle input({Color color = AppColors.stampversePrimaryText}) {
    return _withoutDecoration(
      GoogleFonts.mynerve(
        textStyle: AppStyles.bodyLarge(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ).copyWith(fontSize: 16, height: 1.2),
    );
  }

  static TextStyle button({Color color = AppColors.stampversePrimaryText}) {
    return _withoutDecoration(
      GoogleFonts.mynerve(
        textStyle: AppStyles.buttonLarge(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ).copyWith(fontSize: 16, height: 1.2),
    );
  }

  static TextStyle caption({
    Color color = AppColors.stampverseMutedText,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _withoutDecoration(
      GoogleFonts.mynerve(
        textStyle: AppStyles.bodySmall(color: color, fontWeight: fontWeight),
      ).copyWith(fontSize: 13, height: 1.3),
    );
  }
}
