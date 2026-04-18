import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp_shape.dart';

Path buildTemplateFramePath({
  required StampEditFrameShape frameShape,
  required Rect rect,
}) {
  switch (frameShape) {
    case StampEditFrameShape.stampScallop:
      return buildStampShapePath(rect: rect, shapeType: StampShapeType.scallop);
    case StampEditFrameShape.stampCircle:
      return buildStampShapePath(rect: rect, shapeType: StampShapeType.circle);
    case StampEditFrameShape.stampSquare:
      return buildStampShapePath(rect: rect, shapeType: StampShapeType.square);
    case StampEditFrameShape.stampClassic:
      return _buildClassicStampPath(rect);
    case StampEditFrameShape.plainRect:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
    case StampEditFrameShape.plainCircle:
      return Path()..addOval(rect);
  }
}

Path _buildClassicStampPath(Rect rect) {
  final double minEdge = math.min(rect.width, rect.height);
  final double notchRadius = (minEdge * 0.075).clamp(3.0, 9.0).toDouble();
  final Rect coreRect = rect.deflate(notchRadius);
  final double cornerRadius = (minEdge * 0.075).clamp(3.0, 10.0).toDouble();

  Path merged = Path()
    ..addRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(cornerRadius)),
    );

  final int topCount = math.max(
    4,
    (coreRect.width / (notchRadius * 1.6)).floor(),
  );
  final int sideCount = math.max(
    4,
    (coreRect.height / (notchRadius * 1.6)).floor(),
  );

  for (int i = 0; i < topCount; i += 1) {
    final double t = (i + 0.5) / topCount;
    final double x = coreRect.left + (coreRect.width * t);
    final Rect topCircle = Rect.fromCircle(
      center: Offset(x, coreRect.top),
      radius: notchRadius,
    );
    final Rect bottomCircle = Rect.fromCircle(
      center: Offset(x, coreRect.bottom),
      radius: notchRadius,
    );
    merged = Path.combine(
      PathOperation.union,
      merged,
      Path()..addOval(topCircle),
    );
    merged = Path.combine(
      PathOperation.union,
      merged,
      Path()..addOval(bottomCircle),
    );
  }

  for (int i = 0; i < sideCount; i += 1) {
    final double t = (i + 0.5) / sideCount;
    final double y = coreRect.top + (coreRect.height * t);
    final Rect leftCircle = Rect.fromCircle(
      center: Offset(coreRect.left, y),
      radius: notchRadius,
    );
    final Rect rightCircle = Rect.fromCircle(
      center: Offset(coreRect.right, y),
      radius: notchRadius,
    );
    merged = Path.combine(
      PathOperation.union,
      merged,
      Path()..addOval(leftCircle),
    );
    merged = Path.combine(
      PathOperation.union,
      merged,
      Path()..addOval(rightCircle),
    );
  }

  return merged;
}
