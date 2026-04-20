import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/keys/stampverse_locale_key.dart';
import 'package:stamp_camera/src/ui/edit_board/components/stampverse_edit_studio_view.dart';

const String _kOnePixelPngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMBAAZ7f9sAAAAASUVORK5CYII=';
const String _kSourcePngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAQAAABu2R0fAAAAC0lEQVR42mP8/w8AAgMBgFW2kQAAAABJRU5ErkJggg==';

class _StudioTestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'en_US': <String, String>{
      StampverseLocaleKey.editTemplateSourceGallery: 'From gallery',
      StampverseLocaleKey.editTemplateSourceStamp: 'From saved stamps',
      StampverseLocaleKey.homeEditImportEmpty: 'No stamps available',
      StampverseLocaleKey.editTemplateDelete: 'Delete frame',
      StampverseLocaleKey.editTemplateDuplicate: 'Duplicate frame',
      StampverseLocaleKey.editTemplateLock: 'Lock frame',
      StampverseLocaleKey.editTemplateUnlock: 'Unlock frame',
      StampverseLocaleKey.editTemplateAdjustImage: 'Adjust image',
      StampverseLocaleKey.editTemplateAdjustReset: 'Reset',
      StampverseLocaleKey.editTemplateAdjustHint:
          'Drag, pinch, or rotate to adjust image in frame.',
      'ok': 'OK',
      'cancel': 'Cancel',
    },
  };
}

StampEditBoard _buildTemplateBoard({
  bool isLocked = false,
  double? templateSourceWidth,
  double? templateSourceHeight,
  double layerWidthRatio = 0.4,
  double layerHeightRatio = 0.28,
  StampEditFrameShape frameShape = StampEditFrameShape.plainRect,
}) {
  return StampEditBoard(
    id: 'board_template',
    name: 'Template board',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    editorMode: StampEditBoardEditorMode.template,
    templateSourceWidth: templateSourceWidth,
    templateSourceHeight: templateSourceHeight,
    layers: <StampEditLayer>[
      StampEditLayer(
        id: 'layer_template_1',
        stampId: 'stamp_1',
        imageUrl: _kOnePixelPngDataUrl,
        shapeType: StampShapeType.square,
        centerX: 0.5,
        centerY: 0.5,
        layerType: StampEditLayerType.templateSlot,
        widthRatio: layerWidthRatio,
        heightRatio: layerHeightRatio,
        isLocked: isLocked,
        frameShape: frameShape,
      ),
    ],
  );
}

StampEditBoard _buildMixedTemplateBoard() {
  return const StampEditBoard(
    id: 'board_mixed',
    name: 'Mixed template board',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    editorMode: StampEditBoardEditorMode.template,
    layers: <StampEditLayer>[
      StampEditLayer(
        id: 'layer_stamp',
        stampId: 'stamp_a',
        imageUrl: _kOnePixelPngDataUrl,
        shapeType: StampShapeType.square,
        centerX: 0.3,
        centerY: 0.3,
        layerType: StampEditLayerType.templateSlot,
        widthRatio: 0.36,
        heightRatio: 0.24,
        frameShape: StampEditFrameShape.stampScallop,
      ),
      StampEditLayer(
        id: 'layer_rect',
        stampId: 'stamp_b',
        imageUrl: _kOnePixelPngDataUrl,
        shapeType: StampShapeType.square,
        centerX: 0.68,
        centerY: 0.3,
        layerType: StampEditLayerType.templateSlot,
        widthRatio: 0.28,
        heightRatio: 0.24,
        frameShape: StampEditFrameShape.plainRect,
      ),
      StampEditLayer(
        id: 'layer_circle',
        stampId: 'stamp_c',
        imageUrl: _kOnePixelPngDataUrl,
        shapeType: StampShapeType.square,
        centerX: 0.5,
        centerY: 0.65,
        layerType: StampEditLayerType.templateSlot,
        widthRatio: 0.32,
        heightRatio: 0.32,
        frameShape: StampEditFrameShape.plainCircle,
      ),
    ],
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  testWidgets('shows toolbar and duplicates selected template slot', (
    WidgetTester tester,
  ) async {
    StampEditBoard? latestSaved;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (StampEditBoard board) {
                latestSaved = board;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy_all_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pumpAndSettle();

    expect(latestSaved, isNotNull);
    expect(latestSaved!.layers.length, 2);
  });

  testWidgets('locked template slot does not move on drag gesture', (
    WidgetTester tester,
  ) async {
    int saveCalls = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {
                saveCalls += 1;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder slotFinder = find.byKey(
      const ValueKey<String>('template-layer-layer_template_1'),
    );
    await tester.tap(slotFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await tester.pumpAndSettle();
    final int lockSaveCalls = saveCalls;

    await tester.drag(slotFinder, const Offset(40, 30));
    await tester.pumpAndSettle();

    expect(saveCalls, lockSaveCalls);
  });

  testWidgets('template canvas keeps source image aspect ratio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[
                _buildTemplateBoard(
                  templateSourceWidth: 1696,
                  templateSourceHeight: 2462,
                ),
              ],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size canvasSize = tester.getSize(
      find.byKey(const ValueKey<String>('edit-board-canvas-box')),
    );
    expect(canvasSize.width / canvasSize.height, closeTo(1696 / 2462, 0.001));
  });

  testWidgets('mixed template slot renders stamp, rect, and circle clips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildMixedTemplateBoard()],
              activeBoardId: 'board_mixed',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('template-slot-surface-layer_stamp'),
        ),
        matching: find.byType(ClipPath),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('template-slot-surface-layer_rect'),
        ),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('template-slot-surface-layer_circle'),
        ),
        matching: find.byType(ClipOval),
      ),
      findsOneWidget,
    );
  });

  testWidgets('template toolbar follows selected slot position', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildMixedTemplateBoard()],
              activeBoardId: 'board_mixed',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_stamp')),
    );
    await tester.pumpAndSettle();
    final Offset firstToolbarCenter = tester.getCenter(
      find.byIcon(Icons.copy_all_outlined),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_circle')),
    );
    await tester.pumpAndSettle();
    final Offset secondToolbarCenter = tester.getCenter(
      find.byIcon(Icons.copy_all_outlined),
    );

    expect(
      (firstToolbarCenter - secondToolbarCenter).distance,
      greaterThan(80),
    );
  });

  testWidgets('tap outside board clears selected template slot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.copy_all_outlined), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy_all_outlined), findsNothing);
  });

  testWidgets('selected template slot hides adjust guide outside adjust mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    final Finder surfaceFinder = find.byKey(
      const ValueKey<String>('template-slot-surface-layer_template_1'),
    );
    final Finder customPaintsInSurface = find.descendant(
      of: surfaceFinder,
      matching: find.byType(CustomPaint),
    );
    expect(customPaintsInSurface, findsOneWidget);
  });

  testWidgets('adjust image toolbar action opens template adjust sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (_) {},
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.crop_free_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Adjust image'), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('template-adjust-corner-top-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-corner-top-right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-corner-bottom-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-corner-bottom-right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-edge-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-edge-right')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-edge-bottom')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('template-adjust-edge-left')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Adjust image'), findsNothing);
  });

  testWidgets('dragging top edge handle updates template image scale', (
    WidgetTester tester,
  ) async {
    StampEditBoard? latestSaved;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (StampEditBoard board) {
                latestSaved = board;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.crop_free_rounded));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('template-adjust-edge-top')),
      const Offset(0, -42),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(latestSaved, isNotNull);
    final StampEditLayer updatedLayer = latestSaved!.layers.firstWhere(
      (StampEditLayer layer) => layer.id == 'layer_template_1',
    );
    expect(updatedLayer.contentScale, 1);
    expect(updatedLayer.contentScaleY, greaterThan(1));
  });

  testWidgets('dragging top-left corner handle updates both axis scales', (
    WidgetTester tester,
  ) async {
    StampEditBoard? latestSaved;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[_buildTemplateBoard()],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (StampEditBoard board) {
                latestSaved = board;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.crop_free_rounded));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey<String>('template-adjust-corner-top-left')),
      const Offset(-36, -30),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(latestSaved, isNotNull);
    final StampEditLayer updatedLayer = latestSaved!.layers.firstWhere(
      (StampEditLayer layer) => layer.id == 'layer_template_1',
    );
    expect(updatedLayer.contentScale, 1);
    expect(updatedLayer.contentScaleX, greaterThan(1));
    expect(updatedLayer.contentScaleY, greaterThan(1));
  });

  testWidgets('pinch in adjust modal zooms out slim template slot', (
    WidgetTester tester,
  ) async {
    StampEditBoard? latestSaved;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[
                _buildTemplateBoard(
                  layerWidthRatio: 0.72,
                  layerHeightRatio: 0.12,
                  frameShape: StampEditFrameShape.stampScallop,
                ),
              ],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[],
              onSaveBoard: (StampEditBoard board) {
                latestSaved = board;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.crop_free_rounded));
    await tester.pumpAndSettle();

    final Finder gestureSurface = find.byKey(
      const ValueKey<String>('template-adjust-gesture-surface'),
    );
    final Offset center = tester.getCenter(gestureSurface);
    final TestGesture firstFinger = await tester.startGesture(
      center + const Offset(-70, 0),
      pointer: 1,
    );
    final TestGesture secondFinger = await tester.startGesture(
      center + const Offset(70, 0),
      pointer: 2,
    );
    await tester.pump();
    await firstFinger.moveTo(center + const Offset(-22, 0));
    await secondFinger.moveTo(center + const Offset(22, 0));
    await tester.pumpAndSettle();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(latestSaved, isNotNull);
    final StampEditLayer updatedLayer = latestSaved!.layers.firstWhere(
      (StampEditLayer layer) => layer.id == 'layer_template_1',
    );
    expect(updatedLayer.contentScale, lessThan(1));
  });

  testWidgets('template import from stamp library uses sourceImageUrl', (
    WidgetTester tester,
  ) async {
    StampEditBoard? latestSaved;
    const StampDataModel libraryStamp = StampDataModel(
      id: 'stamp_library_1',
      name: 'Saved stamp',
      imageUrl: _kOnePixelPngDataUrl,
      sourceImageUrl: _kSourcePngDataUrl,
      date: '2026-01-01T00:00:00.000Z',
      shapeType: StampShapeType.scallop,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _StudioTestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StampverseEditStudioView(
              boards: <StampEditBoard>[
                _buildTemplateBoard().copyWith(
                  layers: <StampEditLayer>[
                    _buildTemplateBoard().layers.first.copyWith(imageUrl: ''),
                  ],
                ),
              ],
              activeBoardId: 'board_template',
              stamps: const <StampDataModel>[libraryStamp],
              onSaveBoard: (StampEditBoard board) {
                latestSaved = board;
              },
              showBoardHeader: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('From saved stamps'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('template-layer-layer_template_1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('From saved stamps').first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('template-library-stamp-stamp_library_1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(latestSaved, isNotNull);
    final StampEditLayer updatedLayer = latestSaved!.layers.firstWhere(
      (StampEditLayer layer) => layer.id == 'layer_template_1',
    );
    expect(updatedLayer.imageUrl, _kSourcePngDataUrl);
  });
}
