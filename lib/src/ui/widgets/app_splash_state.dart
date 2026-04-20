import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class AppSplashState extends StatelessWidget {
  const AppSplashState({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.splashBackgroundPng),
          fit: BoxFit.cover,
        ),
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
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.stampverseShadowStrong,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        AppAssets.iconsAppIconPng,
                        width: 128,
                        height: 128,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                24.height,
                Text(
                  title ?? LocaleKey.appName.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.h1(
                    color: AppColors.stampverseHeadingText,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ).copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
