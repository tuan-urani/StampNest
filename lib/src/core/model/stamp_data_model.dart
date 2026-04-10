import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

class StampDataModel extends Equatable {
  const StampDataModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.date,
    this.shapeType = StampShapeType.scallop,
    this.album,
    this.isFavorite = false,
    this.lastOpenedAt,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String date;
  final StampShapeType shapeType;
  final String? album;
  final bool isFavorite;
  final String? lastOpenedAt;

  DateTime? get parsedDate => DateTime.tryParse(date);
  DateTime? get parsedLastOpenedAt {
    final String raw = lastOpenedAt?.trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  StampDataModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? date,
    StampShapeType? shapeType,
    String? album,
    bool? isFavorite,
    Object? lastOpenedAt = _sentinel,
  }) {
    return StampDataModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      shapeType: shapeType ?? this.shapeType,
      album: album ?? this.album,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt == _sentinel
          ? this.lastOpenedAt
          : lastOpenedAt as String?,
    );
  }

  factory StampDataModel.fromJson(Map<String, dynamic> json) {
    final String imageUrl = _readFirstNonEmpty(json, <String>[
      'imageUrl',
      'image_url',
      'image',
      'url',
    ]);
    final String name =
        _readFirstNonEmpty(json, <String>['name', 'title']).isEmpty
        ? 'Untitled memory'
        : _readFirstNonEmpty(json, <String>['name', 'title']);
    final String date =
        _readFirstNonEmpty(json, <String>['date', 'created_at']).isEmpty
        ? DateTime.now().toIso8601String()
        : _readFirstNonEmpty(json, <String>['date', 'created_at']);
    final String id = _readFirstNonEmpty(json, <String>[
      'id',
      '_id',
      'stampId',
      'stamp_id',
    ]);
    final String albumName = _readFirstNonEmpty(json, <String>[
      'album',
      'collection',
    ]);
    final StampShapeType shapeType = stampShapeFromRaw(
      _readFirstNonEmpty(json, <String>['shape', 'shape_type', 'frame']),
    );
    final bool isFavorite = _readBool(json, <String>[
      'isFavorite',
      'is_favorite',
      'favorite',
    ]);
    final String openedAt = _readFirstNonEmpty(json, <String>[
      'lastOpenedAt',
      'last_opened_at',
      'opened_at',
      'recent_at',
    ]);

    return StampDataModel(
      id: id.isEmpty ? _generateFallbackId(json) : id,
      name: name,
      imageUrl: imageUrl,
      date: date,
      shapeType: shapeType,
      album: albumName.isEmpty ? null : albumName,
      isFavorite: isFavorite,
      lastOpenedAt: openedAt.isEmpty ? null : openedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'date': date,
      'shape': shapeType.raw,
      if (album != null) 'album': album,
      'isFavorite': isFavorite,
      if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt,
    };
  }

  static String _readFirstNonEmpty(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = (json[key]?.toString() ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String _generateFallbackId(Map<String, dynamic> json) {
    final String seed = <String>[
      _readFirstNonEmpty(json, <String>['imageUrl', 'image_url', 'image']),
      _readFirstNonEmpty(json, <String>['name', 'title']),
      _readFirstNonEmpty(json, <String>['date', 'created_at']),
      _readFirstNonEmpty(json, <String>['album', 'collection']),
      _readFirstNonEmpty(json, <String>['shape', 'shape_type', 'frame']),
    ].join('|');

    int hash = 5381;
    for (final int codeUnit in seed.codeUnits) {
      hash = ((hash << 5) + hash + codeUnit) & 0x7fffffff;
    }
    return 'fallback_$hash';
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final String normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return false;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    imageUrl,
    date,
    shapeType,
    album,
    isFavorite,
    lastOpenedAt,
  ];
}

const Object _sentinel = Object();
