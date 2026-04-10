import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

class StampUploadRequest {
  const StampUploadRequest({
    required this.name,
    required this.imageUrl,
    required this.date,
    this.shapeType = StampShapeType.scallop,
    this.album,
  });

  final String name;
  final String imageUrl;
  final String date;
  final StampShapeType shapeType;
  final String? album;

  Map<String, dynamic> toJson() {
    final String? albumValue = album?.trim();

    return <String, dynamic>{
      'name': name,
      'imageUrl': imageUrl,
      'date': date,
      if (shapeType != StampShapeType.scallop) 'shape': shapeType.raw,
      if (albumValue != null && albumValue.isNotEmpty) 'album': albumValue,
    };
  }
}
