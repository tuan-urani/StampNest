import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseEditBackgroundPainter extends CustomPainter {
  const StampverseEditBackgroundPainter({required this.backgroundStyle});

  final StampEditBoardBackgroundStyle backgroundStyle;

  @override
  void paint(Canvas canvas, Size size) {
    switch (backgroundStyle) {
      case StampEditBoardBackgroundStyle.grid:
        _paintGrid(canvas, size);
        break;
      case StampEditBoardBackgroundStyle.dots:
        _paintDots(canvas, size);
        break;
      case StampEditBoardBackgroundStyle.paper:
        _paintPaper(canvas, size);
        break;
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    const double gridSize = 24;
    const double majorStep = 5;
    final Paint minor = Paint()
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.65)
      ..strokeWidth = 0.7;
    final Paint major = Paint()
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.95)
      ..strokeWidth = 1;

    int line = 0;
    for (double x = 0; x <= size.width; x += gridSize, line++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        line % majorStep == 0 ? major : minor,
      );
    }

    line = 0;
    for (double y = 0; y <= size.height; y += gridSize, line++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line % majorStep == 0 ? major : minor,
      );
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    const double spacing = 24;
    const int majorStep = 5;
    final Paint minor = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.56);
    final Paint major = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.9);

    int row = 0;
    for (double y = spacing / 2; y <= size.height; y += spacing, row++) {
      int column = 0;
      for (double x = spacing / 2; x <= size.width; x += spacing, column++) {
        final bool isMajor = row % majorStep == 0 && column % majorStep == 0;
        canvas.drawCircle(
          Offset(x, y),
          isMajor ? 1.55 : 0.95,
          isMajor ? major : minor,
        );
      }
    }
  }

  void _paintPaper(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint fill = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, size.height),
        <Color>[
          AppColors.white,
          AppColors.stampverseSurface.withValues(alpha: 0.74),
        ],
      );
    canvas.drawRect(bounds, fill);

    const double lineSpacing = 30;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.22)
      ..strokeWidth = 0.85;

    for (double y = lineSpacing; y <= size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant StampverseEditBackgroundPainter oldDelegate) {
    return oldDelegate.backgroundStyle != backgroundStyle;
  }
}
