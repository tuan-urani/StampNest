import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/widgets/custom_circular_progress.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class AppSplashState extends StatelessWidget {
  const AppSplashState({
    super.key,
    this.title = 'STAMP CAMERA',
    this.tagline,
    this.showProgress = true,
  });

  final String title;
  final String? tagline;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryBackgroundGradient(),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (_, double value, Widget? child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.9),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.stampverseShadowStrong,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        AppAssets.iconsCameraSvg,
                        width: 52,
                        height: 52,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                28.height,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppStyles.h1(
                    color: AppColors.stampverseHeadingText,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ).copyWith(letterSpacing: 1.4),
                ),
                10.height,
                Text(
                  tagline ?? LocaleKey.splashTagline.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyLarge(
                    color: AppColors.stampversePrimaryText,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                34.height,
                if (showProgress)
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CustomCircularProgress(color: AppColors.primary),
                  ),
                if (showProgress) 14.height,
                if (showProgress)
                  Text(
                    LocaleKey.loading.tr,
                    style: AppStyles.bodyMedium(
                      color: AppColors.stampversePrimaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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
