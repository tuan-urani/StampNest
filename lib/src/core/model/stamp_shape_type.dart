enum StampShapeType { scallop, circle, square }

extension StampShapeTypeX on StampShapeType {
  String get raw {
    switch (this) {
      case StampShapeType.scallop:
        return 'scallop';
      case StampShapeType.circle:
        return 'circle';
      case StampShapeType.square:
        return 'square';
    }
  }

  double get aspectRatio {
    switch (this) {
      case StampShapeType.scallop:
        return 120 / 160;
      case StampShapeType.circle:
      case StampShapeType.square:
        return 1;
    }
  }
}

StampShapeType stampShapeFromRaw(String? raw) {
  final String value = (raw ?? '').trim().toLowerCase();
  switch (value) {
    case 'circle':
      return StampShapeType.circle;
    case 'square':
      return StampShapeType.square;
    case 'scallop':
    default:
      return StampShapeType.scallop;
  }
}
