import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/creative_template_spec.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';

const CreativeTemplateSpec templateClassicStampWallV7Spec =
    CreativeTemplateSpec(
      id: 'template_classic_stamp_wall_v7',
      nameLocaleKey: LocaleKey.stampverseCreativeTemplateClassicStampWall,
      sourceWidth: 736,
      sourceHeight: 981,
      showcaseImageAssetPath: AppAssets.creativeTemplateShowcaseTemplate7Png,
      editorBackgroundAssetPath:
          AppAssets.creativeTemplateBackgroundTemplate7Png,
      slotRects: <CreativeTemplateSlotSpec>[
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_1',
          sourceWidth: 736,
          sourceHeight: 981,
          leftPx: 32,
          topPx: 48,
          rightPx: 366,
          bottomPx: 294,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_2',
          sourceWidth: 736,
          sourceHeight: 981,
          leftPx: 392,
          topPx: 170,
          rightPx: 685,
          bottomPx: 567,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_3',
          sourceWidth: 736,
          sourceHeight: 981,
          leftPx: 64,
          topPx: 362,
          rightPx: 340,
          bottomPx: 734,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_4',
          sourceWidth: 736,
          sourceHeight: 981,
          leftPx: 399,
          topPx: 640,
          rightPx: 685,
          bottomPx: 939,
          frameShape: StampEditFrameShape.stampScallop,
        ),
      ],
    );
