import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/extensions/color_extension.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

enum AppPremiumPlan { monthly, yearly }

enum AppPremiumPaywallResult { closed, upgraded }

Future<AppPremiumPaywallResult?> showAppPremiumPaywall(
  BuildContext context, {
  AppPremiumPlan initialPlan = AppPremiumPlan.yearly,
  String backgroundImage = AppAssets.creativeTemplateShowcaseTemplate3Jpg,
}) {
  return showGeneralDialog<AppPremiumPaywallResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'premium_paywall',
    barrierColor: AppColors.black.withOpacityX(0.68),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) {
      return AppPremiumPaywall(
        initialPlan: initialPlan,
        backgroundImage: backgroundImage,
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class AppPremiumPaywall extends StatefulWidget {
  const AppPremiumPaywall({
    super.key,
    this.initialPlan = AppPremiumPlan.yearly,
    this.backgroundImage = AppAssets.creativeTemplateShowcaseTemplate3Jpg,
  });

  final AppPremiumPlan initialPlan;
  final String backgroundImage;

  @override
  State<AppPremiumPaywall> createState() => _AppPremiumPaywallState();
}

class _AppPremiumPaywallState extends State<AppPremiumPaywall> {
  late AppPremiumPlan _selectedPlan;
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
  }

  void _close() {
    Navigator.of(context).pop(AppPremiumPaywallResult.closed);
  }

  Future<void> _continueUpgrade() async {
    if (_isUpgrading) return;

    setState(() {
      _isUpgrading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    Navigator.of(context).pop(AppPremiumPaywallResult.upgraded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(widget.backgroundImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const <double>[0, 0.5, 1],
                  colors: <Color>[
                    AppColors.black.withOpacityX(0.12),
                    AppColors.black.withOpacityX(0.52),
                    AppColors.black.withOpacityX(0.9),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: _CloseButton(onTap: _isUpgrading ? () {} : _close),
                  ),
                  8.height,
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: const Offset(0, -24),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                LocaleKey.stampversePaywallTitle.tr,
                                style: AppStyles.h40(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              10.height,
                              Text(
                                LocaleKey.stampversePaywallSubtitle.tr,
                                style: AppStyles.h1(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                  height: 1.18,
                                ),
                              ),
                              22.height,
                              _BenefitRow(
                                label: LocaleKey
                                    .stampversePaywallBenefitAllFeatures
                                    .tr,
                              ),
                              14.height,
                              _BenefitRow(
                                label: LocaleKey
                                    .stampversePaywallBenefitUnlimitedStamps
                                    .tr,
                              ),
                              24.height,
                              _PlanTile(
                                title:
                                    LocaleKey.stampversePaywallPlanMonthly.tr,
                                price: LocaleKey
                                    .stampversePaywallPlanMonthlyPrice
                                    .tr,
                                selected:
                                    _selectedPlan == AppPremiumPlan.monthly,
                                onTap: () {
                                  setState(() {
                                    _selectedPlan = AppPremiumPlan.monthly;
                                  });
                                },
                              ),
                              12.height,
                              _PlanTile(
                                title: LocaleKey.stampversePaywallPlanYearly.tr,
                                price: LocaleKey
                                    .stampversePaywallPlanYearlyPrice
                                    .tr,
                                badge: LocaleKey
                                    .stampversePaywallPlanYearlyBadge
                                    .tr,
                                selected:
                                    _selectedPlan == AppPremiumPlan.yearly,
                                onTap: () {
                                  setState(() {
                                    _selectedPlan = AppPremiumPlan.yearly;
                                  });
                                },
                              ),
                              18.height,
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _isUpgrading
                                      ? null
                                      : () {
                                          _continueUpgrade();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: AppColors.white,
                                    foregroundColor: AppColors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: 18.borderRadiusAll,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _isUpgrading
                                        ? SizedBox(
                                            key: const ValueKey<String>(
                                              'paywall-upgrading',
                                            ),
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: AppColors.black
                                                  .withOpacityX(0.9),
                                            ),
                                          )
                                        : Text(
                                            key: const ValueKey<String>(
                                              'paywall-upgrade-cta',
                                            ),
                                            LocaleKey
                                                .stampversePaywallCtaStartTrial
                                                .tr,
                                            style: AppStyles.h2(
                                              color: AppColors.black,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withOpacityX(0.18),
      borderRadius: 24.borderRadiusAll,
      child: InkWell(
        borderRadius: 24.borderRadiusAll,
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.close_rounded, color: AppColors.white, size: 30),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.check_rounded,
          color: AppColors.white.withOpacityX(0.8),
          size: 28,
        ),
        12.width,
        Expanded(
          child: Text(
            label,
            style: AppStyles.h4(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withOpacityX(selected ? 0.13 : 0.08),
      borderRadius: 20.borderRadiusAll,
      child: InkWell(
        borderRadius: 20.borderRadiusAll,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: 20.borderRadiusAll,
            border: Border.all(
              color: selected
                  ? AppColors.white
                  : AppColors.white.withOpacityX(0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.white : AppColors.transparent,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.black,
                        size: 24,
                      )
                    : null,
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.h2(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badge != null) ...<Widget>[
                          10.width,
                          Flexible(child: _PlanBadge(label: badge!)),
                        ],
                      ],
                    ),
                    2.height,
                    Text(
                      price,
                      style: AppStyles.h4(
                        color: AppColors.white.withOpacityX(0.78),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacityX(0.95),
        borderRadius: 999.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.bodyMedium(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}
