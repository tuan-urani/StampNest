import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';

abstract class CreativeTemplateSlotSpec extends Equatable {
  const CreativeTemplateSlotSpec({required this.id, required this.frameShape});

  final String id;
  final StampEditFrameShape frameShape;

  StampEditTemplateSlot toTemplateSlot();
}

class CreativeTemplateSlotRect extends CreativeTemplateSlotSpec {
  const CreativeTemplateSlotRect({
    required super.id,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required super.frameShape,
    this.rotation = 0,
  }) : assert(left >= 0 && left <= 1),
       assert(top >= 0 && top <= 1),
       assert(right >= 0 && right <= 1),
       assert(bottom >= 0 && bottom <= 1),
       assert(left < right),
       assert(top < bottom);

  const CreativeTemplateSlotRect.fromSourcePixels({
    required super.id,
    required double sourceWidth,
    required double sourceHeight,
    required double leftPx,
    required double topPx,
    required double rightPx,
    required double bottomPx,
    required super.frameShape,
    this.rotation = 0,
  }) : assert(sourceWidth > 0),
       assert(sourceHeight > 0),
       left = leftPx / sourceWidth,
       top = topPx / sourceHeight,
       right = rightPx / sourceWidth,
       bottom = bottomPx / sourceHeight,
       assert(leftPx >= 0 && leftPx <= sourceWidth),
       assert(topPx >= 0 && topPx <= sourceHeight),
       assert(rightPx >= 0 && rightPx <= sourceWidth),
       assert(bottomPx >= 0 && bottomPx <= sourceHeight),
       assert(leftPx < rightPx),
       assert(topPx < bottomPx);

  final double left;
  final double top;
  final double right;
  final double bottom;
  final double rotation;

  @override
  StampEditTemplateSlot toTemplateSlot() {
    return StampEditTemplateSlot(
      id: id,
      centerX: (left + right) / 2,
      centerY: (top + bottom) / 2,
      widthRatio: right - left,
      heightRatio: bottom - top,
      frameShape: frameShape,
      rotation: rotation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    frameShape,
    left,
    top,
    right,
    bottom,
    rotation,
  ];
}

class CreativeTemplateSlotQuad extends CreativeTemplateSlotSpec {
  const CreativeTemplateSlotQuad({
    required super.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.x3,
    required this.y3,
    required this.x4,
    required this.y4,
    required super.frameShape,
  });

  const CreativeTemplateSlotQuad.fromSourcePixels({
    required super.id,
    required double sourceWidth,
    required double sourceHeight,
    required double x1Px,
    required double y1Px,
    required double x2Px,
    required double y2Px,
    required double x3Px,
    required double y3Px,
    required double x4Px,
    required double y4Px,
    required super.frameShape,
  }) : assert(sourceWidth > 0),
       assert(sourceHeight > 0),
       x1 = x1Px / sourceWidth,
       y1 = y1Px / sourceHeight,
       x2 = x2Px / sourceWidth,
       y2 = y2Px / sourceHeight,
       x3 = x3Px / sourceWidth,
       y3 = y3Px / sourceHeight,
       x4 = x4Px / sourceWidth,
       y4 = y4Px / sourceHeight;

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;
  final double x4;
  final double y4;

  @override
  StampEditTemplateSlot toTemplateSlot() {
    final double centerX = (x1 + x2 + x3 + x4) / 4;
    final double centerY = (y1 + y2 + y3 + y4) / 4;
    final double widthTop = _distance(x1, y1, x2, y2);
    final double widthBottom = _distance(x4, y4, x3, y3);
    final double heightLeft = _distance(x1, y1, x4, y4);
    final double heightRight = _distance(x2, y2, x3, y3);
    final double widthRatio = ((widthTop + widthBottom) / 2).abs();
    final double heightRatio = ((heightLeft + heightRight) / 2).abs();
    final double rotation = math.atan2(y2 - y1, x2 - x1);

    return StampEditTemplateSlot(
      id: id,
      centerX: centerX,
      centerY: centerY,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      frameShape: frameShape,
      rotation: rotation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    frameShape,
    x1,
    y1,
    x2,
    y2,
    x3,
    y3,
    x4,
    y4,
  ];
}

class CreativeTemplateSpec extends Equatable {
  const CreativeTemplateSpec({
    required this.id,
    required this.nameLocaleKey,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.slotRects,
    this.showcaseImageAssetPath,
    this.editorBackgroundAssetPath,
    this.editorCanvasColorHex,
  }) : assert(sourceWidth > 0),
       assert(sourceHeight > 0);

  final String id;
  final String nameLocaleKey;
  final double sourceWidth;
  final double sourceHeight;
  final List<CreativeTemplateSlotSpec> slotRects;
  final String? showcaseImageAssetPath;
  final String? editorBackgroundAssetPath;
  final String? editorCanvasColorHex;

  StampEditTemplate toTemplateModel() {
    return StampEditTemplate(
      id: id,
      nameLocaleKey: nameLocaleKey,
      showcaseImageAssetPath: showcaseImageAssetPath,
      editorBackgroundAssetPath: editorBackgroundAssetPath,
      editorCanvasColorHex: editorCanvasColorHex,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      slots: slotRects
          .map((CreativeTemplateSlotSpec item) => item.toTemplateSlot())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    nameLocaleKey,
    sourceWidth,
    sourceHeight,
    slotRects,
    showcaseImageAssetPath,
    editorBackgroundAssetPath,
    editorCanvasColorHex,
  ];
}

double _distance(double x1, double y1, double x2, double y2) {
  final double dx = x2 - x1;
  final double dy = y2 - y1;
  return math.sqrt((dx * dx) + (dy * dy));
}
