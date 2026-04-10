import 'package:flutter/material.dart';
import '../extensions/color_extension.dart';

class AppColors {
  // ===========================================================================
  // STANDARDIZED TOKEN SET (SINGLE THEME - SOFT/CUTE)
  // ===========================================================================
  // Brand
  static const Color brandPrimary = Color(0xFF84C93F);
  static const Color brandPrimaryAlt = Color(0xFF7BCFB2);
  static const Color brandSecondary = Color(0xFFD8EDC5);
  static const Color brandAccent = Color(0xFF7E8FC7);
  static const Color brandAccentSoft = Color(0xFFE8ECFA);

  // Neutral
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFEFAF5);
  static const Color neutral100 = Color(0xFFF8F5ED);
  static const Color neutral300 = Color(0xFFC0C0C0);
  static const Color neutral500 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF4A4A48);
  static const Color neutral900 = Color(0xFF000000);

  // Surface / Border / Overlay
  static const Color surfacePage = Color(0xFFF8F5ED);
  static const Color surfaceCard = Color(0xFFFEFAF5);
  static const Color surfaceBase = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF5F5F5);
  static const Color borderSoft = Color(0xFFF1EEE7);
  static const Color borderDefault = Color(0xFFE0E0E0);
  static const Color overlayScrim = Color(0x80000000);

  // Semantic
  static const Color semanticSuccess = Color(0xFF6FBE8B);
  static const Color semanticSuccessSoft = Color(0xFFEAF7EF);
  static const Color semanticWarning = Color(0xFFE3B160);
  static const Color semanticError = Color(0xFFE98492);
  static const Color semanticErrorSoft = Color(0xFFFDECEF);
  static const Color semanticInfo = Color(0xFF7FA4D8);

  // State
  static const Color stateFocus = Color(0xFF7E8FC7);
  static const Color stateHover = Color(0xFFEEF3FF);
  static const Color statePressed = Color(0xFFDDECC7);
  static const Color stateDisabledBackground = Color(0xFFECE9E2);
  static const Color stateDisabledText = Color(0xFFB7B2A9);

  // ===========================================================================
  // PRIMARY (LEGACY - ALIASES)
  // ===========================================================================
  static const Color primary = brandPrimary;
  static const Color primaryLight = brandPrimaryAlt;

  /// Alpha variants
  static const Color primaryAlpha10 = Color(0x1A84C93F);

  // Backward compatibility
  static const Color color84C93F = primaryAlpha10;
  static const Color color1A84C93F = primaryAlpha10;

  // ===========================================================================
  // SECONDARY (LEGACY - ALIASES)
  // ===========================================================================
  static const Color secondary1 = brandSecondary;
  static const Color secondary2 = semanticSuccessSoft;

  // ===========================================================================
  // NEUTRAL / BLACK (LEGACY - ALIASES)
  // ===========================================================================
  static const Color black = neutral900;

  // ===========================================================================
  // NEUTRAL / WHITE (LEGACY - ALIASES)
  // ===========================================================================
  static const Color white = neutral0;
  static const Color transparent = Color(0x00000000);

  // ===========================================================================
  // STATUS (LEGACY - ALIASES)
  // ===========================================================================
  static const Color success = semanticSuccess;
  static const Color warning = semanticWarning;
  static const Color error = semanticError;
  static const Color info = semanticInfo;

  // ===========================================================================
  // TEXT (LEGACY - ALIASES)
  // ===========================================================================
  static const Color textPrimary = neutral700;
  static const Color textDisabled = stateDisabledText;
  static const Color textInverse = white;

  // ===========================================================================
  // STAMPVERSE (LEGACY - ALIASES)
  // ===========================================================================
  static const Color stampverseBackground = surfacePage;
  static const Color stampverseSurface = surfaceCard;
  static const Color stampversePrimaryText = neutral500;
  static const Color stampverseHeadingText = neutral700;
  static const Color stampverseMutedText = Color(0xFFA0A09C);
  static const Color stampverseBorderSoft = borderSoft;
  static const Color stampverseDanger = semanticError;
  static const Color stampverseDangerSoft = semanticErrorSoft;
  static const Color stampverseSuccess = semanticSuccess;
  static const Color stampverseSuccessSoft = semanticSuccessSoft;
  static const Color stampverseShadowSoft = Color(0x12000000);
  static const Color stampverseShadowMedium = Color(0x14000000);
  static const Color stampverseShadowStrong = Color(0x1A000000);
  static const Color stampverseShadowCard = Color(0x0D000000);
  static const Color stampverseShadowStamp = Color(0x1F000000);

  static const greyF3 = Color(0xFFF3F3F3);
  static const color2D7DD2 = semanticInfo;
  static const color1D2410 = Color(0xFF1D2410);
  static const color484848 = Color(0xFF484848);
  static const color1C274C = Color(0xFF1C274C);
  static const colorFFF4F2 = Color(0xFFFFF4F2);
  static const colorF5F7FA = Color(0xFFF5F7FA);
  static const colorE6F7ED = Color(0xFFE6F7ED);
  static const color667394 = stateFocus;
  static const colorFF9800 = semanticWarning;
  static const colorB8BCC6 = Color(0xFFB8BCC6);
  static const colorF2F4F7 = Color(0xFFF2F4F7);
  static const colorF9FAFB = Color(0xFFF9FAFB);
  static const colorE1E1E1 = Color(0xFFE1E1E1);
  static const colorE3F2D9 = Color(0xFFE3F2D9);
  static const colorEEEDE9 = Color(0xFFEEEDE9);
  static const color333333 = Color(0xFF333333);
  static const colorEFF8DD = Color(0xFFEFF8DD);
  static const color475467 = Color(0xFF475467);
  static const colorE8EDF5 = Color(0xFFE8EDF5);
  static const colorF4F4F4 = Color(0xFFF4F4F4);
  static const color131A29 = Color(0xFF131A29);
  static const colorD1E8BE = Color(0xFFD1E8BE);
  static const colorE6FAD2 = Color(0xFFE6FAD2);
  static const colorDAFFE0 = Color(0xFFDAFFE0);
  static const color0F000000 = Color(0x0F000000);
  static const colorFAFAFA = Color(0xFFFAFAFA);
  static const colorF8F1DD = Color(0xFFF8F1DD);
  static const colorB7B7B7 = Color(0xFFB7B7B7);
  static const colorFF8C42 = Color(0xFFFF8C42);
  static const color1AFF8C42 = Color(0x1AFF8C42);
  static const colorF1D2BC = Color(0xFFF1D2BC);
  static const colorDFE4F5 = Color(0xFFDFE4F5);
  static const colorF39702 = Color(0xFFF39702);
  static const colorFB1B8D1 = Color(0xFFB1B8D1);
  static const colorF64748B = Color(0xFF64748B);
  static const colorFEF4056 = semanticError;
  static const colorF586AA6 = brandAccent;
  static const colorFDEF1BC = Color(0xFFDEF1BC);
  static const color101828 = Color(0xFF101828);
  static const colorFFE53E = Color(0xFFFFE53E);
  static const colorEEEAE8 = Color(0xFFEEEAE8);
  static const colorEF4056 = semanticError;
  static const color1AEF4056 = Color(0x1AE98492);
  static const colorFF5B42 = Color(0xFFFF5B42);
  static const color33FF5B42 = Color(0x33FF5B42);
  static const color0095FF = semanticInfo;
  static const color1A0095FF = Color(0x1A7FA4D8);
  static const color88CF66 = semanticSuccess;
  static const color1A88CF66 = Color(0x1A6FBE8B);
  static const color1A2D7DD2 = Color(0x1A7E8FC7);
  static const colorFEFEFE = Color(0xFFFEFEFE);
  static const colorDCDFEB = Color(0xFFDCDFEB);
  static const color80586AA6 = brandAccentSoft;
  static const colorF59AEF9 = Color(0xFF59AEF9);
  static const colorFE4F3FF = Color(0xFFE4F3FF);
  static const colorF6B7280 = Color(0xFF6B7280);
  static const colorFE6F4EC = Color(0xFFE6F4EC);
  static const colorFBFC9DE = Color(0xFFBFC9DE);
  static const colorFE7EDF3 = Color(0xFFE7EDF3);
  static const colorFDCDFEB = Color(0xFFDCDFEB);
  static const colorF101828 = Color(0xFF101828);
  static const colorF646C72 = Color(0xFF646C72);
  static const colorF3F7FC9 = Color(0xFF3F7FC9);
  static const colorFA1AEBE = Color(0xFFA1AEBE);
  static const colorEAF9E6 = semanticSuccessSoft;
  static const colorC8E6C9 = Color(0xFFC8E6C9);
  static const colorE3F2FD = Color(0xFFE3F2FD);
  static const colorFFF3E0 = Color(0xFFFFF3E0);
  static const colorF3E5F5 = Color(0xFFF3E5F5);
  static const color9C27B0 = Color(0xFF9C27B0);
  static const colorFAF9F8 = Color(0xFFFAF9F8);
  static const colorCDCDCD = Color(0xFFCDCDCD);
  static const colorD9DEED = Color(0xFFD9DEED);
  static const colorFDFFFD = Color(0xFFFDFFFD);
  static const colorEBEDF0 = Color(0xFFEBEDF0);
  static const colorF8FAFB = Color(0xFFF8FAFB);
  static const colorFFEAEA = semanticErrorSoft;
  static const colorEAECF0 = Color(0xFFEAECF0);
  static const colorFFE2D0 = Color(0xFFFFE2D0);

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================
  static const Color background = surfaceBase;
  static const Color backgroundSecondary = surfaceSecondary;
  static const Color backgroundDisabled = stateDisabledBackground;
  static const Color backgroundOverlay = overlayScrim;

  // ===========================================================================
  // BORDER
  // ===========================================================================
  static const Color border = borderDefault;
  static const Color borderLight = borderSoft;
  static const Color borderDark = Color(0xFFBDBDBD);

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================
  static LinearGradient primaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient secondaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary1],
  );

  static LinearGradient primaryTextGradient() =>
      const LinearGradient(colors: [primary, primaryLight]);

  static LinearGradient fadeGradient() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [black.withOpacityX(0.3), black],
  );

  static LinearGradient disabledGradient() =>
      const LinearGradient(colors: [border, borderDark]);

  static LinearGradient primaryBackgroundGradient() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F7FA), Color(0xFFF2F1EC)],
  );

  // ===========================================================================
  // UTIL
  // ===========================================================================
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
