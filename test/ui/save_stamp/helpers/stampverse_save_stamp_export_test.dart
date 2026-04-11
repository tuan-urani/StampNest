import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/save_stamp/helpers/stampverse_save_stamp_export.dart';

Future<String> _createSolidImageDataUrl({
  required int width,
  required int height,
  required Color color,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) {
    throw StateError('Cannot encode sample image');
  }
  return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
}

Future<ui.Image> _decodeImageFromDataUrl(String dataUrl) async {
  final int commaIndex = dataUrl.indexOf(',');
  final Uint8List bytes = base64Decode(dataUrl.substring(commaIndex + 1));
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  codec.dispose();
  return frameInfo.image;
}

int _alphaAt({
  required ByteData rgba,
  required int width,
  required int x,
  required int y,
}) {
  final int pixelIndex = ((y * width) + x) * 4;
  return rgba.getUint8(pixelIndex + 3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveSaveStampExportSize returns expected size per shape', () {
    final Size scallop = resolveSaveStampExportSize(
      shapeType: StampShapeType.scallop,
    );
    final Size circle = resolveSaveStampExportSize(
      shapeType: StampShapeType.circle,
    );
    final Size square = resolveSaveStampExportSize(
      shapeType: StampShapeType.square,
    );

    expect(scallop.width, 200);
    expect(scallop.height, 267);
    expect(circle.width, 200);
    expect(circle.height, 200);
    expect(square.width, 200);
    expect(square.height, 200);
  });

  test('exportSaveStampImageDataUrl exports clipped transparent PNG', () async {
    final String sourceDataUrl = await _createSolidImageDataUrl(
      width: 60,
      height: 60,
      color: const Color(0xFFFF0000),
    );

    final String? exportedDataUrl = await exportSaveStampImageDataUrl(
      imageUrl: sourceDataUrl,
      shapeType: StampShapeType.circle,
    );
    expect(exportedDataUrl, isNotNull);
    expect(exportedDataUrl, startsWith('data:image/png;base64,'));

    final ui.Image image = await _decodeImageFromDataUrl(exportedDataUrl!);
    final ByteData? rawRgba = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(image.width, 200);
    expect(image.height, 200);
    expect(rawRgba, isNotNull);
    expect(_alphaAt(rgba: rawRgba!, width: image.width, x: 0, y: 0), equals(0));
    expect(
      _alphaAt(rgba: rawRgba, width: image.width, x: 100, y: 100),
      greaterThan(0),
    );
    image.dispose();
  });

  test(
    'exportSaveStampImageDataUrl returns null when source is invalid',
    () async {
      final String? exportedDataUrl = await exportSaveStampImageDataUrl(
        imageUrl: 'invalid_input',
        shapeType: StampShapeType.scallop,
      );

      expect(exportedDataUrl, isNull);
    },
  );
}
