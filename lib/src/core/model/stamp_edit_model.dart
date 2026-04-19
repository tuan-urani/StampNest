import 'package:equatable/equatable.dart';

import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

enum StampEditBoardEditorMode {
  freeform('freeform'),
  template('template');

  const StampEditBoardEditorMode(this.raw);

  final String raw;
}

StampEditBoardEditorMode stampEditBoardEditorModeFromRaw(String? raw) {
  for (final StampEditBoardEditorMode mode in StampEditBoardEditorMode.values) {
    if (mode.raw == raw) return mode;
  }
  return StampEditBoardEditorMode.freeform;
}

enum StampEditBoardBackgroundStyle {
  grid('grid'),
  dots('dots'),
  paper('paper');

  const StampEditBoardBackgroundStyle(this.raw);

  final String raw;
}

StampEditBoardBackgroundStyle stampEditBoardBackgroundStyleFromRaw(
  String? raw,
) {
  for (final StampEditBoardBackgroundStyle style
      in StampEditBoardBackgroundStyle.values) {
    if (style.raw == raw) return style;
  }
  return StampEditBoardBackgroundStyle.grid;
}

enum StampEditLayerType {
  stamp('stamp'),
  templateSlot('template_slot');

  const StampEditLayerType(this.raw);

  final String raw;
}

StampEditLayerType stampEditLayerTypeFromRaw(String? raw) {
  for (final StampEditLayerType type in StampEditLayerType.values) {
    if (type.raw == raw) return type;
  }
  return StampEditLayerType.stamp;
}

class StampEditLayer extends Equatable {
  const StampEditLayer({
    required this.id,
    required this.stampId,
    required this.imageUrl,
    required this.shapeType,
    required this.centerX,
    required this.centerY,
    this.scale = 1,
    this.rotation = 0,
    this.layerType = StampEditLayerType.stamp,
    this.widthRatio,
    this.heightRatio,
    this.isLocked = false,
    this.frameShape = StampEditFrameShape.plainRect,
    this.contentScale = 1,
    this.contentScaleX = 1,
    this.contentScaleY = 1,
    this.contentOffsetX = 0,
    this.contentOffsetY = 0,
    this.contentRotation = 0,
  });

  final String id;
  final String stampId;
  final String imageUrl;
  final StampShapeType shapeType;
  final double centerX;
  final double centerY;
  final double scale;
  final double rotation;
  final StampEditLayerType layerType;
  final double? widthRatio;
  final double? heightRatio;
  final bool isLocked;
  final StampEditFrameShape frameShape;
  final double contentScale;
  final double contentScaleX;
  final double contentScaleY;
  final double contentOffsetX;
  final double contentOffsetY;
  final double contentRotation;

  StampEditLayer copyWith({
    String? id,
    String? stampId,
    String? imageUrl,
    StampShapeType? shapeType,
    double? centerX,
    double? centerY,
    double? scale,
    double? rotation,
    StampEditLayerType? layerType,
    Object? widthRatio = _sentinel,
    Object? heightRatio = _sentinel,
    bool? isLocked,
    StampEditFrameShape? frameShape,
    double? contentScale,
    double? contentScaleX,
    double? contentScaleY,
    double? contentOffsetX,
    double? contentOffsetY,
    double? contentRotation,
  }) {
    return StampEditLayer(
      id: id ?? this.id,
      stampId: stampId ?? this.stampId,
      imageUrl: imageUrl ?? this.imageUrl,
      shapeType: shapeType ?? this.shapeType,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      layerType: layerType ?? this.layerType,
      widthRatio: widthRatio == _sentinel
          ? this.widthRatio
          : widthRatio as double?,
      heightRatio: heightRatio == _sentinel
          ? this.heightRatio
          : heightRatio as double?,
      isLocked: isLocked ?? this.isLocked,
      frameShape: frameShape ?? this.frameShape,
      contentScale: contentScale ?? this.contentScale,
      contentScaleX: contentScaleX ?? this.contentScaleX,
      contentScaleY: contentScaleY ?? this.contentScaleY,
      contentOffsetX: contentOffsetX ?? this.contentOffsetX,
      contentOffsetY: contentOffsetY ?? this.contentOffsetY,
      contentRotation: contentRotation ?? this.contentRotation,
    );
  }

  factory StampEditLayer.fromJson(Map<String, dynamic> json) {
    return StampEditLayer(
      id: (json['id'] ?? '').toString(),
      stampId: (json['stampId'] ?? json['stamp_id'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
      shapeType: stampShapeFromRaw(json['shapeType']?.toString()),
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      layerType: stampEditLayerTypeFromRaw(
        json['layerType']?.toString() ?? json['layer_type']?.toString(),
      ),
      widthRatio:
          (json['widthRatio'] as num?)?.toDouble() ??
          (json['width_ratio'] as num?)?.toDouble(),
      heightRatio:
          (json['heightRatio'] as num?)?.toDouble() ??
          (json['height_ratio'] as num?)?.toDouble(),
      isLocked: json['isLocked'] == true || json['is_locked'] == true,
      frameShape: stampEditFrameShapeFromRaw(
        json['frameShape']?.toString() ?? json['frame_shape']?.toString(),
      ),
      contentScale:
          (json['contentScale'] as num?)?.toDouble() ??
          (json['content_scale'] as num?)?.toDouble() ??
          1,
      contentScaleX:
          (json['contentScaleX'] as num?)?.toDouble() ??
          (json['content_scale_x'] as num?)?.toDouble() ??
          1,
      contentScaleY:
          (json['contentScaleY'] as num?)?.toDouble() ??
          (json['content_scale_y'] as num?)?.toDouble() ??
          1,
      contentOffsetX:
          (json['contentOffsetX'] as num?)?.toDouble() ??
          (json['content_offset_x'] as num?)?.toDouble() ??
          0,
      contentOffsetY:
          (json['contentOffsetY'] as num?)?.toDouble() ??
          (json['content_offset_y'] as num?)?.toDouble() ??
          0,
      contentRotation:
          (json['contentRotation'] as num?)?.toDouble() ??
          (json['content_rotation'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'stampId': stampId,
      'imageUrl': imageUrl,
      'shapeType': shapeType.raw,
      'centerX': centerX,
      'centerY': centerY,
      'scale': scale,
      'rotation': rotation,
      'layerType': layerType.raw,
      if (widthRatio != null) 'widthRatio': widthRatio,
      if (heightRatio != null) 'heightRatio': heightRatio,
      'isLocked': isLocked,
      'frameShape': frameShape.raw,
      'contentScale': contentScale,
      'contentScaleX': contentScaleX,
      'contentScaleY': contentScaleY,
      'contentOffsetX': contentOffsetX,
      'contentOffsetY': contentOffsetY,
      'contentRotation': contentRotation,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    stampId,
    imageUrl,
    shapeType,
    centerX,
    centerY,
    scale,
    rotation,
    layerType,
    widthRatio,
    heightRatio,
    isLocked,
    frameShape,
    contentScale,
    contentScaleX,
    contentScaleY,
    contentOffsetX,
    contentOffsetY,
    contentRotation,
  ];
}

class StampEditBoard extends Equatable {
  const StampEditBoard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.layers = const <StampEditLayer>[],
    this.backgroundStyle = StampEditBoardBackgroundStyle.grid,
    this.editorMode = StampEditBoardEditorMode.freeform,
    this.templateId,
    this.templateBackgroundAssetPath,
    this.templateCanvasColorHex,
    this.templateSourceWidth,
    this.templateSourceHeight,
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<StampEditLayer> layers;
  final StampEditBoardBackgroundStyle backgroundStyle;
  final StampEditBoardEditorMode editorMode;
  final String? templateId;
  final String? templateBackgroundAssetPath;
  final String? templateCanvasColorHex;
  final double? templateSourceWidth;
  final double? templateSourceHeight;

  DateTime get parsedUpdatedAt {
    return DateTime.tryParse(updatedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  StampEditBoard copyWith({
    String? id,
    String? name,
    String? createdAt,
    String? updatedAt,
    List<StampEditLayer>? layers,
    StampEditBoardBackgroundStyle? backgroundStyle,
    StampEditBoardEditorMode? editorMode,
    Object? templateId = _sentinel,
    Object? templateBackgroundAssetPath = _sentinel,
    Object? templateCanvasColorHex = _sentinel,
    Object? templateSourceWidth = _sentinel,
    Object? templateSourceHeight = _sentinel,
  }) {
    return StampEditBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layers: layers ?? this.layers,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      editorMode: editorMode ?? this.editorMode,
      templateId: templateId == _sentinel
          ? this.templateId
          : templateId as String?,
      templateBackgroundAssetPath: templateBackgroundAssetPath == _sentinel
          ? this.templateBackgroundAssetPath
          : templateBackgroundAssetPath as String?,
      templateCanvasColorHex: templateCanvasColorHex == _sentinel
          ? this.templateCanvasColorHex
          : templateCanvasColorHex as String?,
      templateSourceWidth: templateSourceWidth == _sentinel
          ? this.templateSourceWidth
          : templateSourceWidth as double?,
      templateSourceHeight: templateSourceHeight == _sentinel
          ? this.templateSourceHeight
          : templateSourceHeight as double?,
    );
  }

  factory StampEditBoard.fromJson(Map<String, dynamic> json) {
    final dynamic rawLayers = json['layers'];
    final List<StampEditLayer> layers = rawLayers is List
        ? rawLayers
              .whereType<Map<String, dynamic>>()
              .map(StampEditLayer.fromJson)
              .toList(growable: false)
        : const <StampEditLayer>[];

    return StampEditBoard(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
      layers: layers,
      backgroundStyle: stampEditBoardBackgroundStyleFromRaw(
        json['backgroundStyle']?.toString() ??
            json['background_style']?.toString() ??
            json['background']?.toString(),
      ),
      editorMode: stampEditBoardEditorModeFromRaw(
        json['editorMode']?.toString() ?? json['editor_mode']?.toString(),
      ),
      templateId:
          (json['templateId'] ?? json['template_id'])
                  ?.toString()
                  .trim()
                  .isEmpty ==
              true
          ? null
          : (json['templateId'] ?? json['template_id'])?.toString(),
      templateBackgroundAssetPath:
          (json['templateBackgroundAssetPath'] ??
                      json['template_background_asset_path'])
                  ?.toString()
                  .trim()
                  .isEmpty ==
              true
          ? null
          : (json['templateBackgroundAssetPath'] ??
                    json['template_background_asset_path'])
                ?.toString(),
      templateCanvasColorHex:
          (json['templateCanvasColorHex'] ?? json['template_canvas_color_hex'])
                  ?.toString()
                  .trim()
                  .isEmpty ==
              true
          ? null
          : (json['templateCanvasColorHex'] ??
                    json['template_canvas_color_hex'])
                ?.toString(),
      templateSourceWidth: _parseNullableDouble(
        json['templateSourceWidth'] ?? json['template_source_width'],
      ),
      templateSourceHeight: _parseNullableDouble(
        json['templateSourceHeight'] ?? json['template_source_height'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'layers': layers
          .map((StampEditLayer layer) => layer.toJson())
          .toList(growable: false),
      'backgroundStyle': backgroundStyle.raw,
      'editorMode': editorMode.raw,
      if (templateId != null) 'templateId': templateId,
      if (templateBackgroundAssetPath != null)
        'templateBackgroundAssetPath': templateBackgroundAssetPath,
      if (templateCanvasColorHex != null)
        'templateCanvasColorHex': templateCanvasColorHex,
      if (templateSourceWidth != null)
        'templateSourceWidth': templateSourceWidth,
      if (templateSourceHeight != null)
        'templateSourceHeight': templateSourceHeight,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    createdAt,
    updatedAt,
    layers,
    backgroundStyle,
    editorMode,
    templateId,
    templateBackgroundAssetPath,
    templateCanvasColorHex,
    templateSourceWidth,
    templateSourceHeight,
  ];
}

const Object _sentinel = Object();

double? _parseNullableDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}
