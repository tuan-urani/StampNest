import 'dart:ui';

class StampverseImageAdjustments {
  const StampverseImageAdjustments._();

  static const double minBrightness = -1;
  static const double maxBrightness = 1;
  static const double minContrast = 0;
  static const double maxContrast = 2;
  static const double minSaturation = 0;
  static const double maxSaturation = 2;

  static double normalizeBrightness(double value) {
    if (!value.isFinite) return 0;
    return value.clamp(minBrightness, maxBrightness).toDouble();
  }

  static double normalizeContrast(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(minContrast, maxContrast).toDouble();
  }

  static double normalizeSaturation(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(minSaturation, maxSaturation).toDouble();
  }

  static ColorFilter brightnessFilter(double brightness) {
    final double normalized = normalizeBrightness(brightness);
    final double translation = 255 * normalized;
    return ColorFilter.matrix(<double>[
      1,
      0,
      0,
      0,
      translation,
      0,
      1,
      0,
      0,
      translation,
      0,
      0,
      1,
      0,
      translation,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  static ColorFilter contrastFilter(double contrast) {
    final double normalized = normalizeContrast(contrast);
    final double translation = 128 * (1 - normalized);
    return ColorFilter.matrix(<double>[
      normalized,
      0,
      0,
      0,
      translation,
      0,
      normalized,
      0,
      0,
      translation,
      0,
      0,
      normalized,
      0,
      translation,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  static ColorFilter saturationFilter(double saturation) {
    final double normalized = normalizeSaturation(saturation);
    final double inv = 1 - normalized;
    final double r = 0.213 * inv;
    final double g = 0.715 * inv;
    final double b = 0.072 * inv;

    return ColorFilter.matrix(<double>[
      r + normalized,
      g,
      b,
      0,
      0,
      r,
      g + normalized,
      b,
      0,
      0,
      r,
      g,
      b + normalized,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
