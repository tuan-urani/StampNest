import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';

class StampEditTemplateSlot extends Equatable {
  const StampEditTemplateSlot({
    required this.id,
    required this.centerX,
    required this.centerY,
    required this.widthRatio,
    required this.heightRatio,
    required this.frameShape,
    this.rotation = 0,
  });

  final String id;
  final double centerX;
  final double centerY;
  final double widthRatio;
  final double heightRatio;
  final StampEditFrameShape frameShape;
  final double rotation;

  @override
  List<Object?> get props => <Object?>[
    id,
    centerX,
    centerY,
    widthRatio,
    heightRatio,
    frameShape,
    rotation,
  ];
}

class StampEditTemplate extends Equatable {
  const StampEditTemplate({
    required this.id,
    required this.nameLocaleKey,
    required this.slots,
    this.showcaseImageAssetPath,
    this.editorBackgroundAssetPath,
    this.editorCanvasColorHex,
    this.sourceWidth,
    this.sourceHeight,
  });

  final String id;
  final String nameLocaleKey;
  final List<StampEditTemplateSlot> slots;
  final String? showcaseImageAssetPath;
  final String? editorBackgroundAssetPath;
  final String? editorCanvasColorHex;
  final double? sourceWidth;
  final double? sourceHeight;

  @override
  List<Object?> get props => <Object?>[
    id,
    nameLocaleKey,
    slots,
    showcaseImageAssetPath,
    editorBackgroundAssetPath,
    editorCanvasColorHex,
    sourceWidth,
    sourceHeight,
  ];
}
