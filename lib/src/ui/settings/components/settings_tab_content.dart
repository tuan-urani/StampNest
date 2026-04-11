import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/locale/translation_manager.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_shared.dart';

class SettingsTabContent extends StatelessWidget {
  const SettingsTabContent({
    super.key,
    required this.stampsCount,
    required this.collectionsCount,
    required this.onRefresh,
    required this.onResetLocal,
    required this.onOpenPrivacyPolicy,
    required this.onOpenTermsOfUse,
    this.isRefreshing = false,
  });

  final int stampsCount;
  final int collectionsCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onResetLocal;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenTermsOfUse;

  static const List<_SettingsLanguageOption> _languageOptions =
      <_SettingsLanguageOption>[
        _SettingsLanguageOption(
          languageCode: 'vi',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageVietnamese,
        ),
        _SettingsLanguageOption(
          languageCode: 'en',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageEnglish,
        ),
        _SettingsLanguageOption(
          languageCode: 'ja',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageJapanese,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final String selectedLanguageCode = _resolveSelectedLanguageCode();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        StampverseLayout.contentBottomPadding,
      ),
      child: Column(
        children: <Widget>[
          _SettingsLanguageCard(
            label: LocaleKey.stampverseHomeSettingsLanguage.tr,
            selectedLanguageCode: selectedLanguageCode,
            options: _languageOptions,
            onChanged: _onLanguageChanged,
          ),
          const SizedBox(height: 12),
          _SettingsMenuButton(
            icon: Icons.privacy_tip_outlined,
            label: LocaleKey.stampverseHomeSettingsPrivacyPolicy.tr,
            onTap: onOpenPrivacyPolicy,
          ),
          const SizedBox(height: 10),
          _SettingsMenuButton(
            icon: Icons.description_outlined,
            label: LocaleKey.stampverseHomeSettingsTermsOfUse.tr,
            onTap: onOpenTermsOfUse,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            stampsCount: stampsCount,
            collectionsCount: collectionsCount,
          ),
          const SizedBox(height: 12),
          _SettingsActionButton(
            icon: Icons.refresh_rounded,
            label: LocaleKey.stampverseHomeSettingsRefresh.tr,
            onTap: onRefresh,
            loading: isRefreshing,
          ),
          const SizedBox(height: 10),
          _SettingsActionButton(
            icon: Icons.delete_forever_rounded,
            label: LocaleKey.stampverseHomeSettingsResetLocal.tr,
            onTap: onResetLocal,
            danger: true,
          ),
        ],
      ),
    );
  }

  String _resolveSelectedLanguageCode() {
    final String currentLanguageCode =
        Get.locale?.languageCode ??
        TranslationManager.defaultLocale.languageCode;
    for (final _SettingsLanguageOption option in _languageOptions) {
      if (option.languageCode == currentLanguageCode) {
        return currentLanguageCode;
      }
    }
    return TranslationManager.defaultLocale.languageCode;
  }

  Future<void> _onLanguageChanged(String? languageCode) async {
    if (languageCode == null || languageCode.isEmpty) return;
    final Locale targetLocale =
        TranslationManager.resolveLocaleFromLanguageCode(languageCode);

    await Get.find<AppShared>().setLanguageCode(languageCode);
    await Get.updateLocale(targetLocale);
  }
}

class _SettingsLanguageOption {
  const _SettingsLanguageOption({
    required this.languageCode,
    required this.labelKey,
  });

  final String languageCode;
  final String labelKey;
}

class _SettingsLanguageCard extends StatelessWidget {
  const _SettingsLanguageCard({
    required this.label,
    required this.selectedLanguageCode,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String selectedLanguageCode;
  final List<_SettingsLanguageOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stampverseBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.language_rounded,
            size: 18,
            color: AppColors.stampversePrimaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: StampverseTextStyles.body(
                color: AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguageCode,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: AppColors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.stampverseMutedText,
              ),
              style: StampverseTextStyles.caption(
                color: AppColors.stampverseHeadingText,
                fontWeight: FontWeight.w700,
              ),
              items: options
                  .map(
                    (_SettingsLanguageOption option) =>
                        DropdownMenuItem<String>(
                          value: option.languageCode,
                          child: Text(option.labelKey.tr),
                        ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stampverseBorderSoft),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 14),
                Icon(icon, size: 18, color: AppColors.stampversePrimaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: StampverseTextStyles.body(
                      color: AppColors.stampversePrimaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.stampverseMutedText,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stampsCount, required this.collectionsCount});

  final int stampsCount;
  final int collectionsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stampverseBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatItem(
              label: LocaleKey.stampverseHomeSettingsTotalStamps.tr,
              value: '$stampsCount',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.stampverseBorderSoft,
          ),
          Expanded(
            child: _StatItem(
              label: LocaleKey.stampverseHomeSettingsTotalCollections.tr,
              value: '$collectionsCount',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: StampverseTextStyles.heroTitle(
            color: AppColors.stampverseHeadingText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: StampverseTextStyles.caption(),
        ),
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color foreground = danger
        ? AppColors.stampverseDanger
        : AppColors.stampversePrimaryText;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stampverseBorderSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: StampverseTextStyles.body(
                    color: foreground,
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
