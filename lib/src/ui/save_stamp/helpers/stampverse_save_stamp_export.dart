import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp_shape.dart';

const double kSaveStampPreviewBaseWidth = 200;

Size resolveSaveStampPreviewSize({
  required StampShapeType shapeType,
  double baseWidth = kSaveStampPreviewBaseWidth,
}) {
  final double resolvedWidth = baseWidth > 0
      ? baseWidth
      : kSaveStampPreviewBaseWidth;
  final double aspectRatio = shapeType.aspectRatio > 0
      ? shapeType.aspectRatio
      : 1;
  return Size(resolvedWidth, resolvedWidth / aspectRatio);
}

Size resolveSaveStampExportSize({
  required StampShapeType shapeType,
  double baseWidth = kSaveStampPreviewBaseWidth,
}) {
  final Size previewSize = resolveSaveStampPreviewSize(
    shapeType: shapeType,
    baseWidth: baseWidth,
  );
  final int targetWidth = previewSize.width.round().clamp(1, 4096);
  final int targetHeight = previewSize.height.round().clamp(1, 4096);
  return Size(targetWidth.toDouble(), targetHeight.toDouble());
}

Future<String?> exportSaveStampImageDataUrl({
  required String imageUrl,
  required StampShapeType shapeType,
  double baseWidth = kSaveStampPreviewBaseWidth,
}) async {
  final Uint8List? sourceBytes = await _resolveImageBytes(imageUrl);
  if (sourceBytes == null || sourceBytes.isEmpty) return null;

  ui.Codec? codec;
  ui.Image? sourceImage;
  ui.Image? outputImage;

  try {
    codec = await ui.instantiateImageCodec(sourceBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    sourceImage = frameInfo.image;

    final Size outputSize = resolveSaveStampExportSize(
      shapeType: shapeType,
      baseWidth: baseWidth,
    );
    final int targetWidth = outputSize.width.toInt();
    final int targetHeight = outputSize.height.toInt();
    final Rect targetRect = Rect.fromLTWH(
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );
    final Path shapePath = buildStampShapePath(
      rect: targetRect,
      shapeType: shapeType,
    );

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.clipPath(shapePath, doAntiAlias: true);
    canvas.drawImageRect(
      sourceImage,
      Rect.fromLTWH(
        0,
        0,
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      ),
      targetRect,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );

    final ui.Picture picture = recorder.endRecording();
    outputImage = await picture.toImage(targetWidth, targetHeight);
    final ByteData? outputData = await outputImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (outputData == null) return null;

    final String encoded = base64Encode(outputData.buffer.asUint8List());
    return 'data:image/png;base64,$encoded';
  } catch (_) {
    return null;
  } finally {
    outputImage?.dispose();
    sourceImage?.dispose();
    codec?.dispose();
  }
}

Future<Uint8List?> _resolveImageBytes(String value) async {
  if (value.isEmpty) return null;

  try {
    if (value.startsWith('data:image')) {
      final int commaIndex = value.indexOf(',');
      if (commaIndex < 0 || commaIndex >= value.length - 1) return null;
      return base64Decode(value.substring(commaIndex + 1));
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final ByteData data = await NetworkAssetBundle(
        Uri.parse(value),
      ).load(value);
      return data.buffer.asUint8List();
    }

    if (_isLikelyLocalPath(value)) {
      final String path = value.startsWith('file://')
          ? Uri.parse(value).toFilePath()
          : value;
      final File file = File(path);
      if (!file.existsSync()) return null;
      return file.readAsBytes();
    }

    final ByteData data = await rootBundle.load(value);
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

bool _isLikelyLocalPath(String value) {
  return value.startsWith('/') || value.startsWith('file://');
}
