import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

enum StampEditFrameShape {
  stampScallop('stamp_scallop'),
  stampCircle('stamp_circle'),
  stampSquare('stamp_square'),
  stampClassic('stamp_classic'),
  plainRect('plain_rect'),
  plainCircle('plain_circle');

  const StampEditFrameShape(this.raw);

  final String raw;

  bool get isStampShape {
    switch (this) {
      case StampEditFrameShape.stampScallop:
      case StampEditFrameShape.stampCircle:
      case StampEditFrameShape.stampSquare:
      case StampEditFrameShape.stampClassic:
        return true;
      case StampEditFrameShape.plainRect:
      case StampEditFrameShape.plainCircle:
        return false;
    }
  }

  StampShapeType? get stampShapeType {
    switch (this) {
      case StampEditFrameShape.stampScallop:
        return StampShapeType.scallop;
      case StampEditFrameShape.stampCircle:
        return StampShapeType.circle;
      case StampEditFrameShape.stampSquare:
        return StampShapeType.square;
      case StampEditFrameShape.stampClassic:
        return null;
      case StampEditFrameShape.plainRect:
      case StampEditFrameShape.plainCircle:
        return null;
    }
  }
}

StampEditFrameShape stampEditFrameShapeFromRaw(String? raw) {
  for (final StampEditFrameShape shape in StampEditFrameShape.values) {
    if (shape.raw == raw) return shape;
  }
  return StampEditFrameShape.plainRect;
}
