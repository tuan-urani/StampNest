import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

void main() {
  test('toJson/fromJson keeps sourceImageUrl', () {
    const StampDataModel source = StampDataModel(
      id: 'stamp_1',
      name: 'My stamp',
      imageUrl: 'data:image/png;base64,stamped',
      sourceImageUrl: 'data:image/png;base64,source',
      date: '2026-01-01T00:00:00.000Z',
      shapeType: StampShapeType.scallop,
      album: 'My album',
    );

    final StampDataModel restored = StampDataModel.fromJson(source.toJson());

    expect(restored.imageUrl, source.imageUrl);
    expect(restored.sourceImageUrl, source.sourceImageUrl);
    expect(restored.shapeType, source.shapeType);
  });
}
