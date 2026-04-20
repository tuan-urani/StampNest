import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/creative_template_spec.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';

const CreativeTemplateSpec templateClassicStampWallV6Spec =
    CreativeTemplateSpec(
      id: 'template_classic_stamp_wall_v6',
      nameLocaleKey: LocaleKey.stampverseCreativeTemplateClassicStampWall,
      sourceWidth: 736,
      sourceHeight: 736,
      showcaseImageAssetPath: AppAssets.creativeTemplateShowcaseTemplate6Png,
      editorBackgroundAssetPath:
          AppAssets.creativeTemplateBackgroundTemplate6Png,
      slotRects: <CreativeTemplateSlotSpec>[
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_1',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 72,
          topPx: 123,
          rightPx: 254,
          bottomPx: 358,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_2',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 277,
          topPx: 122,
          rightPx: 459,
          bottomPx: 357,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_3',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 483,
          topPx: 123,
          rightPx: 664,
          bottomPx: 358,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_4',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 72,
          topPx: 378,
          rightPx: 255,
          bottomPx: 613,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_5',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 277,
          topPx: 378,
          rightPx: 459,
          bottomPx: 613,
          frameShape: StampEditFrameShape.stampScallop,
        ),
        CreativeTemplateSlotRect.fromSourcePixels(
          id: 'slot_6',
          sourceWidth: 736,
          sourceHeight: 736,
          leftPx: 483,
          topPx: 378,
          rightPx: 664,
          bottomPx: 613,
          frameShape: StampEditFrameShape.stampScallop,
        ),
      ],
    );
