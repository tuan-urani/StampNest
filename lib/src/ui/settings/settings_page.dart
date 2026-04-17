import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/settings/components/settings_tab_content.dart';
import 'package:stamp_camera/src/ui/settings/interactor/settings_page_cubit.dart';
import 'package:stamp_camera/src/ui/settings/interactor/settings_page_state.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_tab_scaffold.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_top_round_action_button.dart';
import 'package:stamp_camera/src/ui/widgets/app_inapp_webview.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String _privacyPolicyAssetFilePath = 'web/privacy-policy.html';
  static const String _termsOfUseAssetFilePath = 'web/terms-of-use.html';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stampverseBackground,
      body: BlocProvider<SettingsPageCubit>(
        create: (_) =>
            SettingsPageCubit(repository: Get.find<StampverseRepository>())
              ..initialize(),
        child: BlocBuilder<SettingsPageCubit, SettingsPageState>(
          builder: (BuildContext context, SettingsPageState state) {
            final SettingsPageCubit cubit = context.read<SettingsPageCubit>();
            return StampverseTabScaffold(
              title: LocaleKey.stampverseHomeTabSettings.tr,
              leading: StampverseTopRoundActionButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              child: SettingsTabContent(
                stampsCount: state.stampsCount,
                collectionsCount: state.collectionsCount,
                onClearLocalData: () async {
                  final bool shouldClear = await _confirmClearLocalData(
                    context,
                  );
                  if (!context.mounted || !shouldClear) return;
                  await cubit.clearLocalData();
                },
                onOpenPrivacyPolicy: () {
                  _openLegalDocument(
                    context: context,
                    title: LocaleKey.stampverseHomeSettingsPrivacyPolicy.tr,
                    assetFilePath: _privacyPolicyAssetFilePath,
                    preferredLanguageCode: _resolveLegalLanguageCode(),
                  );
                },
                onOpenTermsOfUse: () {
                  _openLegalDocument(
                    context: context,
                    title: LocaleKey.stampverseHomeSettingsTermsOfUse.tr,
                    assetFilePath: _termsOfUseAssetFilePath,
                    preferredLanguageCode: _resolveLegalLanguageCode(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openLegalDocument({
    required BuildContext context,
    required String title,
    required String assetFilePath,
    required String preferredLanguageCode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StampverseLegalWebViewPage(
          title: title,
          assetFilePath: assetFilePath,
          preferredLanguageCode: preferredLanguageCode,
        ),
      ),
    );
  }

  String _resolveLegalLanguageCode() {
    final String appLanguageCode =
        Get.locale?.languageCode.toLowerCase() ?? 'vi';
    if (appLanguageCode == 'vi') return 'vi';
    if (appLanguageCode == 'ja') return 'ja';
    return 'en';
  }

  Future<bool> _confirmClearLocalData(BuildContext context) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.stampverseSurface,
          title: Text(
            LocaleKey.stampverseHomeSettingsResetLocalTitle.tr,
            style: StampverseTextStyles.body(
              color: AppColors.stampverseHeadingText,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            LocaleKey.stampverseHomeSettingsResetLocalBody.tr,
            style: StampverseTextStyles.body(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LocaleKey.widgetCancel.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                LocaleKey.stampverseHomeSettingsResetLocalConfirm.tr,
                style: StampverseTextStyles.body(
                  color: AppColors.stampverseDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }
}

class _StampverseLegalWebViewPage extends StatelessWidget {
  const _StampverseLegalWebViewPage({
    required this.title,
    required this.assetFilePath,
    required this.preferredLanguageCode,
  });

  final String title;
  final String assetFilePath;
  final String preferredLanguageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stampverseBackground,
      appBar: AppBar(
        backgroundColor: AppColors.stampverseBackground,
        foregroundColor: AppColors.stampverseHeadingText,
        elevation: 0,
        title: Text(
          title,
          style: StampverseTextStyles.body(
            color: AppColors.stampverseHeadingText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: AppInAppWebView(
          assetFilePath: assetFilePath,
          preferredLanguageCode: preferredLanguageCode,
        ),
      ),
    );
  }
}
