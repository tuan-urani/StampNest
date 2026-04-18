import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/locale/keys/stampverse_locale_key.dart';
import 'package:stamp_camera/src/ui/creative/components/creative_mode_segment.dart';
import 'package:stamp_camera/src/ui/creative/components/creative_template_content.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'en_US': <String, String>{
      StampverseLocaleKey.homeCreativeModeTemplates: 'Templates',
      StampverseLocaleKey.homeCreativeModeBoards: 'My boards',
      StampverseLocaleKey.creativeTemplateSectionTitle: 'Template gallery',
      StampverseLocaleKey.creativeTemplateHint: 'Template hint',
      StampverseLocaleKey.creativeTemplateUse: 'Use template',
      StampverseLocaleKey.creativeTemplateStoryGrid: 'Story grid',
      StampverseLocaleKey.creativeTemplateCategorySectionTitle:
          'Choose template type',
      StampverseLocaleKey.creativeTemplateFeaturedSectionTitle: 'Featured',
      StampverseLocaleKey.creativeTemplateAllSectionTitle: 'All templates',
      StampverseLocaleKey.creativeTemplateCategoryClassicStampWall:
          'Classic Stamp Wall',
      StampverseLocaleKey.creativeTemplateCategoryBotanicalPostage:
          'Botanical Postage',
      StampverseLocaleKey.creativeTemplateCategoryCuteAnime: 'Cute Anime',
      StampverseLocaleKey.creativeTemplateMoodClassic: 'classic',
      StampverseLocaleKey.creativeTemplateMoodBotanical: 'botanical',
      StampverseLocaleKey.creativeTemplateMoodCuteAnime: 'anime',
      StampverseLocaleKey.creativeTemplateBadgeHot: 'HOT',
      StampverseLocaleKey.creativeTemplateBadgeNew: 'NEW',
      StampverseLocaleKey.homeStampsCount: '@count stamps',
    },
  };
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  testWidgets('CreativeModeSegment emits selected mode', (
    WidgetTester tester,
  ) async {
    CreativeViewMode? changedMode;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: _TestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CreativeModeSegment(
            mode: CreativeViewMode.templates,
            onChanged: (CreativeViewMode mode) {
              changedMode = mode;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('My boards'));
    await tester.pumpAndSettle();

    expect(changedMode, CreativeViewMode.boards);
  });

  testWidgets('CreativeTemplateContent emits selected template', (
    WidgetTester tester,
  ) async {
    final StampEditTemplate template = StampEditTemplate(
      id: 'template_story_grid_v1',
      nameLocaleKey: StampverseLocaleKey.creativeTemplateStoryGrid,
      slots: const <StampEditTemplateSlot>[],
    );
    StampEditTemplate? selectedTemplate;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: _TestTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CreativeTemplateContent(
            templates: <StampEditTemplate>[template],
            onSelectTemplate: (StampEditTemplate value) {
              selectedTemplate = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>('creative-template-featured-card-${template.id}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(selectedTemplate?.id, template.id);
  });
}
