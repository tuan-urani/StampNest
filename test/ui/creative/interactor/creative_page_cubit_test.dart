import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:stamp_camera/src/api/stampverse_api.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_cubit.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_template_catalog.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/creative_template_spec.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StampverseRepository repository;
  late CreativePageCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    repository = StampverseRepository(
      api: StampverseApi(dio: Dio()),
      preferences: preferences,
    );
    cubit = CreativePageCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('createBoardFromTemplate creates and saves template board', () async {
    final String? boardId = await cubit.createBoardFromTemplate(
      template: creativeTemplateCatalog.first,
      templateName: 'Classic wall',
    );

    expect(boardId, isNotNull);
    final List<StampEditBoard> boards = await repository.readEditBoardsCache();
    expect(boards, isNotEmpty);
    expect(boards.first.id, boardId);
    expect(boards.first.editorMode, StampEditBoardEditorMode.template);
    expect(boards.first.templateId, creativeTemplateCatalog.first.id);
    expect(
      boards.first.layers.length,
      creativeTemplateCatalog.first.slots.length,
    );
    expect(
      boards.first.layers.every(
        (StampEditLayer layer) =>
            layer.layerType == StampEditLayerType.templateSlot,
      ),
      isTrue,
    );
    expect(
      boards.first.layers.map((StampEditLayer layer) => layer.frameShape),
      creativeTemplateCatalog.first.slots.map(
        (StampEditTemplateSlot slot) => slot.frameShape,
      ),
    );
    expect(
      boards.first.layers.any(
        (StampEditLayer layer) =>
            layer.frameShape == StampEditFrameShape.stampClassic,
      ),
      isTrue,
    );
    expect(boards.first.templateSourceWidth, 1024);
    expect(boards.first.templateSourceHeight, 1024);
    expect(cubit.state.viewMode, CreativeViewMode.boards);
  });

  test('classic stamp wall template keeps showcase and 3x3 classic slots', () {
    final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
      (StampEditTemplate item) => item.id == 'template_classic_stamp_wall_v1',
    );

    expect(template.showcaseImageAssetPath, isNotEmpty);
    expect(template.editorBackgroundAssetPath, isNull);
    expect(template.sourceWidth, 1024);
    expect(template.sourceHeight, 1024);
    expect(template.slots.length, 9);
    expect(
      template.slots.every(
        (StampEditTemplateSlot slot) =>
            slot.frameShape == StampEditFrameShape.stampClassic,
      ),
      isTrue,
    );
  });

  test(
    'classic stamp wall v6 template keeps background and 6 scallop slots',
    () {
      final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
        (StampEditTemplate item) => item.id == 'template_classic_stamp_wall_v6',
      );

      expect(
        template.showcaseImageAssetPath,
        AppAssets.creativeTemplateShowcaseTemplate6Png,
      );
      expect(
        template.editorBackgroundAssetPath,
        AppAssets.creativeTemplateBackgroundTemplate6Png,
      );
      expect(template.sourceWidth, 736);
      expect(template.sourceHeight, 736);
      expect(template.slots.length, 6);
      expect(
        template.slots.every(
          (StampEditTemplateSlot slot) =>
              slot.frameShape == StampEditFrameShape.stampScallop,
        ),
        isTrue,
      );
    },
  );

  test(
    'classic stamp wall v7 template keeps background and 4 scallop slots',
    () {
      final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
        (StampEditTemplate item) => item.id == 'template_classic_stamp_wall_v7',
      );

      expect(
        template.showcaseImageAssetPath,
        AppAssets.creativeTemplateShowcaseTemplate7Png,
      );
      expect(
        template.editorBackgroundAssetPath,
        AppAssets.creativeTemplateBackgroundTemplate7Png,
      );
      expect(template.sourceWidth, 736);
      expect(template.sourceHeight, 981);
      expect(template.slots.length, 4);
      expect(
        template.slots.every(
          (StampEditTemplateSlot slot) =>
              slot.frameShape == StampEditFrameShape.stampScallop,
        ),
        isTrue,
      );
    },
  );

  test('night stamp collage template has dark background and 12 slots', () {
    final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
      (StampEditTemplate item) => item.id == 'template_night_stamp_collage_v2',
    );

    expect(template.showcaseImageAssetPath, isNotEmpty);
    expect(
      template.editorBackgroundAssetPath,
      AppAssets.creativeTemplateBackgroundTemplate2Png,
    );
    expect(template.editorCanvasColorHex, '#000000');
    expect(template.sourceWidth, 736);
    expect(template.sourceHeight, 1041);
    expect(template.slots.length, 12);
    expect(
      template.slots.every(
        (StampEditTemplateSlot slot) =>
            slot.frameShape == StampEditFrameShape.stampClassic,
      ),
      isTrue,
    );
  });

  test('retro postage patchwork template has background and 18 slots', () {
    final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
      (StampEditTemplate item) =>
          item.id == 'template_retro_postage_patchwork_v3',
    );

    expect(
      template.showcaseImageAssetPath,
      AppAssets.creativeTemplateShowcaseTemplate3Jpg,
    );
    expect(
      template.editorBackgroundAssetPath,
      AppAssets.creativeTemplateBackgroundTemplate3Png,
    );
    expect(template.sourceWidth, 1696);
    expect(template.sourceHeight, 2462);
    expect(template.slots.length, 18);
    expect(
      template.slots.every(
        (StampEditTemplateSlot slot) =>
            slot.frameShape == StampEditFrameShape.stampScallop,
      ),
      isTrue,
    );
    expect(
      template.slots.first.rotation,
      closeTo(math.atan2(0.0553 - 0.0508, 0.3866 - 0.1848), 0.00001),
    );
    expect(
      template.slots.last.rotation,
      closeTo(math.atan2(0.7934 - 0.7934, 0.8538 - 0.6577), 0.00001),
    );
  });

  test('botanical postage template has background and 6 slots', () {
    final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
      (StampEditTemplate item) => item.id == 'template_botanical_postage_v4',
    );

    expect(
      template.showcaseImageAssetPath,
      AppAssets.creativeTemplateShowcaseTemplate4Png,
    );
    expect(
      template.editorBackgroundAssetPath,
      AppAssets.creativeTemplateBackgroundTemplate4Png,
    );
    expect(template.sourceWidth, 736);
    expect(template.sourceHeight, 1308);
    expect(template.slots.length, 6);
    expect(
      template.slots.every(
        (StampEditTemplateSlot slot) =>
            slot.frameShape == StampEditFrameShape.stampScallop,
      ),
      isTrue,
    );
  });

  test('createBoardFromTemplate keeps template canvas color', () async {
    final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
      (StampEditTemplate item) => item.id == 'template_night_stamp_collage_v2',
    );

    final String? boardId = await cubit.createBoardFromTemplate(
      template: template,
      templateName: 'Night collage',
    );

    expect(boardId, isNotNull);
    final List<StampEditBoard> boards = await repository.readEditBoardsCache();
    expect(boards.first.id, boardId);
    expect(boards.first.templateCanvasColorHex, '#000000');
    expect(
      boards.first.templateBackgroundAssetPath,
      AppAssets.creativeTemplateBackgroundTemplate2Png,
    );
  });

  test(
    'createBoardFromTemplate keeps template background asset path',
    () async {
      final StampEditTemplate template = creativeTemplateCatalog.firstWhere(
        (StampEditTemplate item) =>
            item.id == 'template_retro_postage_patchwork_v3',
      );

      final String? boardId = await cubit.createBoardFromTemplate(
        template: template,
        templateName: 'Retro patchwork',
      );

      expect(boardId, isNotNull);
      final List<StampEditBoard> boards = await repository
          .readEditBoardsCache();
      expect(boards.first.id, boardId);
      expect(
        boards.first.templateBackgroundAssetPath,
        AppAssets.creativeTemplateBackgroundTemplate3Png,
      );
    },
  );

  test(
    'template specs keep source image dimensions for common coordinate space',
    () {
      final CreativeTemplateSpec classic = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_classic_stamp_wall_v1',
      );
      final CreativeTemplateSpec night = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_night_stamp_collage_v2',
      );
      final CreativeTemplateSpec retro = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_retro_postage_patchwork_v3',
      );
      final CreativeTemplateSpec botanical = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_botanical_postage_v4',
      );
      final CreativeTemplateSpec classicV6 = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_classic_stamp_wall_v6',
      );
      final CreativeTemplateSpec classicV7 = creativeTemplateSpecs.firstWhere(
        (CreativeTemplateSpec item) =>
            item.id == 'template_classic_stamp_wall_v7',
      );

      expect(classic.sourceWidth, 1024);
      expect(classic.sourceHeight, 1024);
      expect(night.sourceWidth, 736);
      expect(night.sourceHeight, 1041);
      expect(retro.sourceWidth, 1696);
      expect(retro.sourceHeight, 2462);
      expect(botanical.sourceWidth, 736);
      expect(botanical.sourceHeight, 1308);
      expect(classicV6.sourceWidth, 736);
      expect(classicV6.sourceHeight, 736);
      expect(classicV7.sourceWidth, 736);
      expect(classicV7.sourceHeight, 981);
    },
  );

  test('slot rect from source pixels converts to normalized ratios', () {
    const CreativeTemplateSlotRect rect =
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot',
          sourceWidth: 736,
          sourceHeight: 1041,
          leftPx: 27.968,
          topPx: 34.561,
          rightPx: 219.254,
          bottomPx: 286.171,
          frameShape: StampEditFrameShape.stampClassic,
        );

    expect(rect.left, closeTo(0.0380, 0.00001));
    expect(rect.top, closeTo(0.0332, 0.00001));
    expect(rect.right, closeTo(0.2979, 0.00001));
    expect(rect.bottom, closeTo(0.2749, 0.00001));
  });

  test('slot quad converts to center, size, and rotation', () {
    const CreativeTemplateSlotQuad quad = CreativeTemplateSlotQuad(
      id: 'slot_quad',
      x1: 0.4,
      y1: 0.5,
      x2: 0.5,
      y2: 0.4,
      x3: 0.6,
      y3: 0.5,
      x4: 0.5,
      y4: 0.6,
      frameShape: StampEditFrameShape.stampScallop,
    );

    final StampEditTemplateSlot slot = quad.toTemplateSlot();
    expect(slot.centerX, closeTo(0.5, 0.00001));
    expect(slot.centerY, closeTo(0.5, 0.00001));
    expect(slot.widthRatio, closeTo(0.141421, 0.00001));
    expect(slot.heightRatio, closeTo(0.141421, 0.00001));
    expect(slot.rotation, closeTo(-math.pi / 4, 0.00001));
  });
}
