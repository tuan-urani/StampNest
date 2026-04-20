import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/creative_template_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_botanical_postage_v4_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_classic_stamp_wall_v1_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_classic_stamp_wall_v6_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_classic_stamp_wall_v7_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_night_stamp_collage_v2_spec.dart';
import 'package:stamp_camera/src/ui/creative/interactor/template_specs/template_retro_postage_patchwork_v3_spec.dart';

const List<CreativeTemplateSpec> creativeTemplateSpecs = <CreativeTemplateSpec>[
  templateClassicStampWallV1Spec,
  templateClassicStampWallV6Spec,
  templateClassicStampWallV7Spec,
  templateNightStampCollageV2Spec,
  templateRetroPostagePatchworkV3Spec,
  templateBotanicalPostageV4Spec,
];

final List<StampEditTemplate> creativeTemplateCatalog = creativeTemplateSpecs
    .map((CreativeTemplateSpec spec) => spec.toTemplateModel())
    .toList(growable: false);
