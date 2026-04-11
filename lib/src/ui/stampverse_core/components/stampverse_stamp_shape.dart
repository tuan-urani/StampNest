import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

Path buildStampShapePath({
  required Rect rect,
  required StampShapeType shapeType,
}) {
  switch (shapeType) {
    case StampShapeType.scallop:
      return buildStampScallopedPath(rect);
    case StampShapeType.circle:
      return buildCircleScallopedPath(rect);
    case StampShapeType.square:
      return buildSquareScallopedPath(rect);
  }
}

Path buildStampScallopedPath(Rect rect) {
  return _buildRectScallopedPath(
    rect,
    notchRadiusScale: 0.042,
    minRadius: 4.0,
    maxRadius: 7.0,
    horizontalDivisor: 44,
    verticalDivisor: 44,
    notchSpacingFactor: 3.2,
    minNotchCount: 6,
  );
}

Path buildSquareScallopedPath(Rect rect) {
  return _buildRectScallopedPath(
    rect,
    notchRadiusScale: 0.046,
    minRadius: 4.2,
    maxRadius: 7.2,
    horizontalDivisor: 40,
    verticalDivisor: 40,
    notchSpacingFactor: 3.5,
    minNotchCount: 6,
  );
}

Path _buildRectScallopedPath(
  Rect rect, {
  required double notchRadiusScale,
  required double minRadius,
  required double maxRadius,
  required double horizontalDivisor,
  required double verticalDivisor,
  required double notchSpacingFactor,
  required int minNotchCount,
}) {
  final double minEdge = math.min(rect.width, rect.height);
  final double adaptiveMinRadius = (minEdge * 0.03)
      .clamp(1.25, minRadius)
      .toDouble();
  final double notchRadius = (minEdge * notchRadiusScale)
      .clamp(adaptiveMinRadius, maxRadius)
      .toDouble();
  final int topCount = math.max(
    minNotchCount,
    math.max(
      (rect.width / horizontalDivisor).round(),
      (rect.width / (notchRadius * notchSpacingFactor)).round(),
    ),
  );
  final int sideCount = math.max(
    minNotchCount,
    math.max(
      (rect.height / verticalDivisor).round(),
      (rect.height / (notchRadius * notchSpacingFactor)).round(),
    ),
  );

  final Path base = Path()..addRect(rect);
  final Path notches = Path();
  final double topStep = rect.width / (topCount + 1);
  final double sideStep = rect.height / (sideCount + 1);

  for (int index = 1; index <= topCount; index += 1) {
    final double x = rect.left + (topStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.top), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.bottom), radius: notchRadius),
    );
  }

  for (int index = 1; index <= sideCount; index += 1) {
    final double y = rect.top + (sideStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
    );
  }

  final Path scallopedPath = Path.combine(
    PathOperation.difference,
    base,
    notches,
  );
  final double cornerRadius = (notchRadius * 0.9)
      .clamp(1.0, minEdge / 8)
      .toDouble();
  final Path cornerMask = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));

  return Path.combine(PathOperation.intersect, scallopedPath, cornerMask);
}

Path buildCircleScallopedPath(Rect rect) {
  final Path base = Path()..addOval(rect);
  final double minEdge = math.min(rect.width, rect.height);
  final double notchRadius = (minEdge * 0.035).clamp(3.2, 5.8).toDouble();
  final double perimeter = 2 * math.pi * (minEdge / 2);
  final int notchCount = math.max(18, (perimeter / 20).round());

  final double cx = rect.center.dx;
  final double cy = rect.center.dy;
  final double rx = rect.width / 2;
  final double ry = rect.height / 2;

  final Path notches = Path();
  for (int index = 0; index < notchCount; index += 1) {
    final double theta = (2 * math.pi * index) / notchCount;
    final double x = cx + (rx * math.cos(theta));
    final double y = cy + (ry * math.sin(theta));
    notches.addOval(Rect.fromCircle(center: Offset(x, y), radius: notchRadius));
  }

  return Path.combine(PathOperation.difference, base, notches);
}
