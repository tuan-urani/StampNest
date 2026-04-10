import 'package:equatable/equatable.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

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
  });

  final String id;
  final String stampId;
  final String imageUrl;
  final StampShapeType shapeType;
  final double centerX;
  final double centerY;
  final double scale;
  final double rotation;

  StampEditLayer copyWith({
    String? id,
    String? stampId,
    String? imageUrl,
    StampShapeType? shapeType,
    double? centerX,
    double? centerY,
    double? scale,
    double? rotation,
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
  ];
}

class StampEditBoard extends Equatable {
  const StampEditBoard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.layers = const <StampEditLayer>[],
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<StampEditLayer> layers;

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
  }) {
    return StampEditBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layers: layers ?? this.layers,
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
    };
  }

  @override
  List<Object?> get props => <Object?>[id, name, createdAt, updatedAt, layers];
}
