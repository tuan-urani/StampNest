import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';

const String _kOnePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMBAAZ7f9sAAAAASUVORK5CYII=';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({required bool applyShapeClip}) {
    final Uint8List imageBytes = base64Decode(_kOnePixelPngBase64);
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: StampverseStamp(
            imageUrl: '',
            imageBytes: imageBytes,
            shapeType: StampShapeType.scallop,
            applyShapeClip: applyShapeClip,
            width: 120,
          ),
        ),
      ),
    );
  }

  testWidgets('uses ClipPath when applyShapeClip is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject(applyShapeClip: true));
    await tester.pumpAndSettle();

    expect(find.byType(ClipPath), findsOneWidget);
  });

  testWidgets('does not use ClipPath when applyShapeClip is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject(applyShapeClip: false));
    await tester.pumpAndSettle();

    expect(find.byType(ClipPath), findsNothing);
  });
}
