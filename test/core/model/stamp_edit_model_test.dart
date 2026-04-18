import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

void main() {
  test('fromJson keeps backward compatibility for old payload', () {
    final StampEditBoard board = StampEditBoard.fromJson(<String, dynamic>{
      'id': 'board_1',
      'name': 'Legacy',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'layers': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'layer_1',
          'stampId': 'stamp_1',
          'imageUrl': 'https://example.com/1.png',
          'shapeType': 'circle',
          'centerX': 0.5,
          'centerY': 0.5,
          'scale': 1.2,
          'rotation': 0.1,
        },
      ],
    });

    expect(board.editorMode, StampEditBoardEditorMode.freeform);
    expect(board.templateId, isNull);
    expect(board.templateBackgroundAssetPath, isNull);
    expect(board.templateCanvasColorHex, isNull);
    expect(board.templateSourceWidth, isNull);
    expect(board.templateSourceHeight, isNull);
    expect(board.layers.single.layerType, StampEditLayerType.stamp);
    expect(board.layers.single.widthRatio, isNull);
    expect(board.layers.single.heightRatio, isNull);
    expect(board.layers.single.isLocked, isFalse);
    expect(board.layers.single.frameShape, StampEditFrameShape.plainRect);
  });

  test('toJson/fromJson keeps new template fields', () {
    const StampEditLayer templateLayer = StampEditLayer(
      id: 'layer_template',
      stampId: 'stamp_1',
      imageUrl: 'data:image/png;base64,abc',
      shapeType: StampShapeType.square,
      centerX: 0.4,
      centerY: 0.6,
      rotation: 0.2,
      layerType: StampEditLayerType.templateSlot,
      widthRatio: 0.42,
      heightRatio: 0.28,
      isLocked: true,
      frameShape: StampEditFrameShape.stampScallop,
    );
    const StampEditBoard source = StampEditBoard(
      id: 'board_template',
      name: 'Template board',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
      layers: <StampEditLayer>[templateLayer],
      editorMode: StampEditBoardEditorMode.template,
      templateId: 'template_story_grid_v1',
      templateBackgroundAssetPath: 'assets/template_1.png',
      templateCanvasColorHex: '#000000',
      templateSourceWidth: 736,
      templateSourceHeight: 1041,
    );

    final StampEditBoard restored = StampEditBoard.fromJson(source.toJson());

    expect(restored.editorMode, StampEditBoardEditorMode.template);
    expect(restored.templateId, 'template_story_grid_v1');
    expect(restored.templateBackgroundAssetPath, 'assets/template_1.png');
    expect(restored.templateCanvasColorHex, '#000000');
    expect(restored.templateSourceWidth, 736);
    expect(restored.templateSourceHeight, 1041);
    expect(restored.layers.single.layerType, StampEditLayerType.templateSlot);
    expect(restored.layers.single.widthRatio, closeTo(0.42, 0.00001));
    expect(restored.layers.single.heightRatio, closeTo(0.28, 0.00001));
    expect(restored.layers.single.isLocked, isTrue);
    expect(restored.layers.single.frameShape, StampEditFrameShape.stampScallop);
  });
}
