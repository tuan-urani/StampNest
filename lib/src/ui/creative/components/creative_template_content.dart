import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/widgets/app_premium_paywall.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_template_frame_path.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CreativeTemplateContent extends StatefulWidget {
  const CreativeTemplateContent({
    super.key,
    required this.templates,
    required this.onSelectTemplate,
    this.enableAssetFrameOverlay = false,
  });

  final List<StampEditTemplate> templates;
  final ValueChanged<StampEditTemplate> onSelectTemplate;
  final bool enableAssetFrameOverlay;

  @override
  State<CreativeTemplateContent> createState() =>
      _CreativeTemplateContentState();
}

class _CreativeTemplateContentState extends State<CreativeTemplateContent> {
  _CreativeTemplateCategory _selectedCategory =
      _CreativeTemplateCategory.classicStampWall;
  bool _isPremiumUnlocked = false;

  bool _isPremiumCategory(_CreativeTemplateCategory category) {
    return category == _CreativeTemplateCategory.botanicalPostage ||
        category == _CreativeTemplateCategory.cuteAnime;
  }

  Future<void> _requestPremiumAccess({required VoidCallback onGranted}) async {
    if (_isPremiumUnlocked) {
      onGranted();
      return;
    }

    final AppPremiumPaywallResult? result = await showAppPremiumPaywall(
      context,
    );
    if (!mounted) return;
    if (result != AppPremiumPaywallResult.upgraded) return;

    setState(() {
      _isPremiumUnlocked = true;
    });
    _showPremiumUnlockedToast();
    onGranted();
  }

  void _showPremiumUnlockedToast() {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(LocaleKey.stampversePaywallUpgradeSuccess.tr)),
      );
  }

  List<_CategorizedTemplate> _buildCategorizedTemplates() {
    return widget.templates
        .asMap()
        .entries
        .map((MapEntry<int, StampEditTemplate> entry) {
          return _CategorizedTemplate(
            index: entry.key,
            template: entry.value,
            category: _resolveTemplateCategory(template: entry.value),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final List<_CategorizedTemplate> categorizedTemplates =
        _buildCategorizedTemplates();

    final Map<_CreativeTemplateCategory, List<_CategorizedTemplate>> grouped =
        <_CreativeTemplateCategory, List<_CategorizedTemplate>>{
          for (final _CreativeTemplateCategory category
              in _CreativeTemplateCategory.values)
            category: categorizedTemplates
                .where((_CategorizedTemplate item) => item.category == category)
                .toList(growable: false),
        };

    final List<_CategorizedTemplate> selectedTemplates =
        grouped[_selectedCategory] ?? const <_CategorizedTemplate>[];

    final _CategorizedTemplate? featuredTemplate = selectedTemplates.isNotEmpty
        ? selectedTemplates.first
        : (categorizedTemplates.isNotEmpty ? categorizedTemplates.first : null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        StampverseLayout.contentBottomPadding,
      ),
      children: <Widget>[
        _SectionTitle(
          title: LocaleKey.stampverseCreativeTemplateCategorySectionTitle.tr,
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.colorF39702,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _CreativeTemplateCategory.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.79,
          ),
          itemBuilder: (_, int index) {
            final _CreativeTemplateCategory category =
                _CreativeTemplateCategory.values[index];
            final List<_CategorizedTemplate> categoryTemplates =
                grouped[category] ?? const <_CategorizedTemplate>[];
            final _CategorizedTemplate? representative =
                categoryTemplates.isNotEmpty ? categoryTemplates.first : null;

            return _TemplateCategoryCard(
              key: ValueKey<String>(
                'creative-template-category-${category.name}',
              ),
              category: category,
              representative: representative,
              enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
              isSelected: category == _selectedCategory,
              onTap: () {
                if (_isPremiumCategory(category)) {
                  _requestPremiumAccess(
                    onGranted: () {
                      if (_selectedCategory == category) return;
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                  return;
                }
                if (_selectedCategory == category) return;
                setState(() {
                  _selectedCategory = category;
                });
              },
            );
          },
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: LocaleKey.stampverseCreativeTemplateFeaturedSectionTitle.tr,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.colorFF8C42,
        ),
        const SizedBox(height: 10),
        if (featuredTemplate != null)
          _FeaturedTemplateCard(
            key: ValueKey<String>(
              'creative-template-featured-card-${featuredTemplate.template.id}',
            ),
            item: featuredTemplate,
            enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
            onTap: () {
              if (_isPremiumCategory(featuredTemplate.category)) {
                _requestPremiumAccess(
                  onGranted: () =>
                      widget.onSelectTemplate(featuredTemplate.template),
                );
                return;
              }
              widget.onSelectTemplate(featuredTemplate.template);
            },
          )
        else
          const SizedBox.shrink(),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(
              child: _SectionTitle(
                title: LocaleKey.stampverseCreativeTemplateAllSectionTitle.tr,
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.colorB7B7B7,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.stampverseMutedText,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selectedTemplates.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedTemplates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (_, int index) {
              final _CategorizedTemplate item = selectedTemplates[index];
              return _TemplateCompactCard(
                key: ValueKey<String>(
                  'creative-template-card-${item.template.id}',
                ),
                item: item,
                enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
                onTap: () {
                  if (_isPremiumCategory(item.category)) {
                    _requestPremiumAccess(
                      onGranted: () => widget.onSelectTemplate(item.template),
                    );
                    return;
                  }
                  widget.onSelectTemplate(item.template);
                },
              );
            },
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: StampverseTextStyles.heroTitle(
              color: AppColors.stampverseHeadingText,
            ).copyWith(fontSize: 23),
          ),
        ),
        Icon(icon, size: 22, color: iconColor),
      ],
    );
  }
}

class _TemplateCategoryCard extends StatelessWidget {
  const _TemplateCategoryCard({
    super.key,
    required this.category,
    required this.representative,
    required this.enableAssetFrameOverlay,
    required this.isSelected,
    required this.onTap,
  });

  final _CreativeTemplateCategory category;
  final _CategorizedTemplate? representative;
  final bool enableAssetFrameOverlay;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _TemplateCardTone tone = _TemplateCardTone.resolve(
      category: category,
      index: representative?.index ?? 0,
    );

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? tone.badgeColor
                  : AppColors.stampverseBorderSoft,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.stampverseShadowCard,
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: tone.previewTintColor.withValues(alpha: 0.24),
                      child: representative == null
                          ? Center(
                              child: Icon(
                                category.icon,
                                size: 28,
                                color: tone.badgeColor,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(4),
                              child: _TemplateShowcaseSurface(
                                template: representative!.template,
                                enableAssetFrameOverlay:
                                    enableAssetFrameOverlay,
                                borderRadius: 10,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  category.titleLocaleKey.tr,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StampverseTextStyles.sectionTitle(
                    color: AppColors.stampverseHeadingText,
                  ).copyWith(fontSize: 14, letterSpacing: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedTemplateCard extends StatelessWidget {
  const _FeaturedTemplateCard({
    super.key,
    required this.item,
    required this.enableAssetFrameOverlay,
    required this.onTap,
  });

  final _CategorizedTemplate item;
  final bool enableAssetFrameOverlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _TemplateCardTone tone = _TemplateCardTone.resolve(
      category: item.category,
      index: item.index,
    );

    final String countLabel = LocaleKey.stampverseHomeStampsCount.trParams(
      <String, String>{'count': '${item.template.slots.length}'},
    );
    final String subtitle = '$countLabel · ${item.category.moodLocaleKey.tr}';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.stampverseBorderSoft),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.stampverseShadowCard,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AspectRatio(
              aspectRatio: 2.02,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.stampverseSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stampverseBorderSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 56,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: tone.previewTintColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: _TemplateShowcaseSurface(
                                      template: item.template,
                                      enableAssetFrameOverlay:
                                          enableAssetFrameOverlay,
                                      borderRadius: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.template.nameLocaleKey.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StampverseTextStyles.sectionTitle(
                                color: AppColors.stampverseHeadingText,
                              ).copyWith(fontSize: 14, letterSpacing: 0.1),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StampverseTextStyles.caption(
                                color: AppColors.stampverseMutedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 44,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                _TemplateRibbonBadge(
                                  label: LocaleKey
                                      .stampverseCreativeTemplateBadgeHot
                                      .tr,
                                  color: AppColors.colorFF8C42,
                                  icon: Icons.local_fire_department_rounded,
                                ),
                                _TemplateRibbonBadge(
                                  label: LocaleKey
                                      .stampverseCreativeTemplateBadgeNew
                                      .tr,
                                  color: AppColors.colorF59AEF9,
                                  icon: Icons.fiber_new_rounded,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item.template.nameLocaleKey.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: StampverseTextStyles.sectionTitle(
                                color: AppColors.stampverseHeadingText,
                              ).copyWith(fontSize: 20, height: 1.1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StampverseTextStyles.caption(
                                color: AppColors.stampverseMutedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _TemplateUseButton(
                              tone: tone,
                              label: LocaleKey.stampverseCreativeTemplateUse.tr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCompactCard extends StatelessWidget {
  const _TemplateCompactCard({
    super.key,
    required this.item,
    required this.enableAssetFrameOverlay,
    required this.onTap,
  });

  final _CategorizedTemplate item;
  final bool enableAssetFrameOverlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _TemplateCardTone tone = _TemplateCardTone.resolve(
      category: item.category,
      index: item.index,
    );
    final String countLabel = LocaleKey.stampverseHomeStampsCount.trParams(
      <String, String>{'count': '${item.template.slots.length}'},
    );
    final String subtitle = '$countLabel · ${item.category.moodLocaleKey.tr}';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stampverseBorderSoft),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.stampverseShadowCard,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tone.previewTintColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: _TemplateShowcaseSurface(
                                template: item.template,
                                enableAssetFrameOverlay:
                                    enableAssetFrameOverlay,
                                borderRadius: 10,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _TemplateBadge(tone: tone),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.template.nameLocaleKey.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StampverseTextStyles.sectionTitle(
                    color: AppColors.stampverseHeadingText,
                  ).copyWith(fontSize: 16, height: 1.1, letterSpacing: 0.1),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StampverseTextStyles.caption(
                    color: AppColors.stampverseMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateRibbonBadge extends StatelessWidget {
  const _TemplateRibbonBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 11, color: AppColors.white),
            const SizedBox(width: 2),
            Text(
              label,
              style: StampverseTextStyles.caption(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 9, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateShowcaseSurface extends StatelessWidget {
  const _TemplateShowcaseSurface({
    required this.template,
    required this.enableAssetFrameOverlay,
    required this.borderRadius,
  });

  final StampEditTemplate template;
  final bool enableAssetFrameOverlay;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final String showcasePath = template.showcaseImageAssetPath?.trim() ?? '';
    if (showcasePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: AppColors.white,
          child: Image.asset(
            showcasePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _GeneratedTemplatePreview(
              template: template,
              enableAssetFrameOverlay: enableAssetFrameOverlay,
            ),
          ),
        ),
      );
    }

    return _GeneratedTemplatePreview(
      template: template,
      enableAssetFrameOverlay: enableAssetFrameOverlay,
    );
  }
}

class _GeneratedTemplatePreview extends StatelessWidget {
  const _GeneratedTemplatePreview({
    required this.template,
    required this.enableAssetFrameOverlay,
  });

  final StampEditTemplate template;
  final bool enableAssetFrameOverlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.white),
        child: Stack(
          children: template.slots
              .map((StampEditTemplateSlot slot) {
                return Align(
                  alignment: Alignment(
                    (slot.centerX * 2) - 1,
                    (slot.centerY * 2) - 1,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: slot.widthRatio,
                    heightFactor: slot.heightRatio,
                    child: Transform.rotate(
                      angle: slot.rotation,
                      child: _TemplatePreviewFrame(
                        frameShape: slot.frameShape,
                        enableAssetFrameOverlay: enableAssetFrameOverlay,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _TemplateBadge extends StatelessWidget {
  const _TemplateBadge({required this.tone});

  final _TemplateCardTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.badgeColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.stampverseShadowCard,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(tone.badgeIcon, size: 14, color: tone.badgeIconColor),
      ),
    );
  }
}

class _TemplateUseButton extends StatelessWidget {
  const _TemplateUseButton({required this.tone, required this.label});

  final _TemplateCardTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.actionColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tone.actionColor.withValues(alpha: 0.45)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.stampverseShadowSoft,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: tone.actionTextColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: StampverseTextStyles.button(
                    color: tone.actionTextColor,
                  ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorizedTemplate {
  const _CategorizedTemplate({
    required this.index,
    required this.template,
    required this.category,
  });

  final int index;
  final StampEditTemplate template;
  final _CreativeTemplateCategory category;
}

enum _CreativeTemplateCategory { classicStampWall, botanicalPostage, cuteAnime }

extension _CreativeTemplateCategoryX on _CreativeTemplateCategory {
  String get titleLocaleKey {
    switch (this) {
      case _CreativeTemplateCategory.classicStampWall:
        return LocaleKey.stampverseCreativeTemplateCategoryClassicStampWall;
      case _CreativeTemplateCategory.botanicalPostage:
        return LocaleKey.stampverseCreativeTemplateCategoryBotanicalPostage;
      case _CreativeTemplateCategory.cuteAnime:
        return LocaleKey.stampverseCreativeTemplateCategoryCuteAnime;
    }
  }

  String get moodLocaleKey {
    switch (this) {
      case _CreativeTemplateCategory.classicStampWall:
        return LocaleKey.stampverseCreativeTemplateMoodClassic;
      case _CreativeTemplateCategory.botanicalPostage:
        return LocaleKey.stampverseCreativeTemplateMoodBotanical;
      case _CreativeTemplateCategory.cuteAnime:
        return LocaleKey.stampverseCreativeTemplateMoodCuteAnime;
    }
  }

  IconData get icon {
    switch (this) {
      case _CreativeTemplateCategory.classicStampWall:
        return Icons.grid_view_rounded;
      case _CreativeTemplateCategory.botanicalPostage:
        return Icons.eco_rounded;
      case _CreativeTemplateCategory.cuteAnime:
        return Icons.pets_rounded;
    }
  }
}

_CreativeTemplateCategory _resolveTemplateCategory({
  required StampEditTemplate template,
}) {
  final String templateId = template.id.toLowerCase();
  if (templateId == 'template_classic_stamp_wall_v7') {
    return _CreativeTemplateCategory.cuteAnime;
  }
  if (templateId.contains('classic')) {
    return _CreativeTemplateCategory.classicStampWall;
  }
  if (templateId.contains('botanical') || templateId.contains('night')) {
    return _CreativeTemplateCategory.botanicalPostage;
  }
  return _CreativeTemplateCategory.cuteAnime;
}

class _TemplateCardTone {
  const _TemplateCardTone({
    required this.badgeColor,
    required this.badgeIcon,
    required this.badgeIconColor,
    required this.previewTintColor,
    required this.actionColor,
    required this.actionTextColor,
  });

  final Color badgeColor;
  final IconData badgeIcon;
  final Color badgeIconColor;
  final Color previewTintColor;
  final Color actionColor;
  final Color actionTextColor;

  static _TemplateCardTone resolve({
    required _CreativeTemplateCategory category,
    required int index,
  }) {
    switch (category) {
      case _CreativeTemplateCategory.classicStampWall:
        return const _TemplateCardTone(
          badgeColor: AppColors.colorF586AA6,
          badgeIcon: Icons.auto_awesome_rounded,
          badgeIconColor: AppColors.white,
          previewTintColor: AppColors.colorDFE4F5,
          actionColor: AppColors.semanticSuccess,
          actionTextColor: AppColors.white,
        );
      case _CreativeTemplateCategory.botanicalPostage:
        return const _TemplateCardTone(
          badgeColor: AppColors.semanticSuccess,
          badgeIcon: Icons.eco_rounded,
          badgeIconColor: AppColors.white,
          previewTintColor: AppColors.colorE6F7ED,
          actionColor: AppColors.colorFF8C42,
          actionTextColor: AppColors.white,
        );
      case _CreativeTemplateCategory.cuteAnime:
        return index.isEven
            ? const _TemplateCardTone(
                badgeColor: AppColors.colorFF8C42,
                badgeIcon: Icons.favorite_rounded,
                badgeIconColor: AppColors.white,
                previewTintColor: AppColors.colorF1D2BC,
                actionColor: AppColors.colorF586AA6,
                actionTextColor: AppColors.white,
              )
            : const _TemplateCardTone(
                badgeColor: AppColors.colorF59AEF9,
                badgeIcon: Icons.star_rounded,
                badgeIconColor: AppColors.white,
                previewTintColor: AppColors.colorE8EDF5,
                actionColor: AppColors.semanticWarning,
                actionTextColor: AppColors.white,
              );
    }
  }
}

class _TemplatePreviewFrame extends StatelessWidget {
  const _TemplatePreviewFrame({
    required this.frameShape,
    required this.enableAssetFrameOverlay,
  });

  final StampEditFrameShape frameShape;
  final bool enableAssetFrameOverlay;

  String? _frameOverlayAssetPath() {
    if (!enableAssetFrameOverlay) return null;
    switch (frameShape) {
      case StampEditFrameShape.stampScallop:
        return AppAssets.creativeTemplateStampFrameOverlayPng;
      case StampEditFrameShape.stampCircle:
      case StampEditFrameShape.stampSquare:
      case StampEditFrameShape.stampClassic:
      case StampEditFrameShape.plainRect:
      case StampEditFrameShape.plainCircle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect rect = Offset.zero & size;
        final Path path = buildTemplateFramePath(
          frameShape: frameShape,
          rect: rect,
        );
        final bool isClassicStamp =
            frameShape == StampEditFrameShape.stampClassic;
        final double innerInset = (math.min(size.width, size.height) * 0.16)
            .clamp(3.0, 10.0)
            .toDouble();
        final Color classicInnerBorderColor = AppColors.stampversePrimaryText
            .withValues(alpha: 0.8);
        final Color borderColor = frameShape == StampEditFrameShape.stampClassic
            ? AppColors.stampversePrimaryText
            : AppColors.white;
        final String? overlayAssetPath = _frameOverlayAssetPath();
        final bool showPainterBorder = overlayAssetPath == null;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (isClassicStamp)
              ClipPath(
                clipper: _TemplatePreviewClipper(path),
                child: const ColoredBox(color: AppColors.colorF8F1DD),
              )
            else
              ClipPath(
                clipper: _TemplatePreviewClipper(path),
                child: ColoredBox(
                  color: AppColors.stampverseBorderSoft.withValues(alpha: 0.55),
                ),
              ),
            if (isClassicStamp)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(innerInset),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.stampverseBorderSoft.withValues(
                        alpha: 0.55,
                      ),
                      border: Border.all(
                        color: classicInnerBorderColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            CustomPaint(
              painter: showPainterBorder
                  ? _TemplatePreviewBorderPainter(
                      path: path,
                      borderColor: borderColor,
                    )
                  : null,
            ),
            if (overlayAssetPath != null)
              IgnorePointer(
                child: Image.asset(
                  overlayAssetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const Center(
              child: Icon(
                Icons.add_circle_rounded,
                size: 18,
                color: AppColors.stampverseMutedText,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TemplatePreviewClipper extends CustomClipper<Path> {
  const _TemplatePreviewClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _TemplatePreviewClipper oldClipper) {
    return oldClipper.path != path;
  }
}

class _TemplatePreviewBorderPainter extends CustomPainter {
  const _TemplatePreviewBorderPainter({
    required this.path,
    required this.borderColor,
  });

  final Path path;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _TemplatePreviewBorderPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.borderColor != borderColor;
  }
}
