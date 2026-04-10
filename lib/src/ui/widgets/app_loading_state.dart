import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/widgets/custom_circular_progress.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.title,
    this.message,
    this.backgroundColor = AppColors.background,
    this.indicatorColor = AppColors.primary,
    this.maxWidth = 320,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  final String? title;
  final String? message;
  final Color backgroundColor;
  final Color indicatorColor;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryAlpha10,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Center(
                        child: CustomCircularProgress(color: indicatorColor),
                      ),
                    ),
                  ),
                  16.height,
                  Text(
                    title ?? LocaleKey.loading.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.h4(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  8.height,
                  Text(
                    message ?? LocaleKey.pleaseWait.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyLarge(
                      color: AppColors.stampverseMutedText,
                      height: 1.3,
                    ),
                  ),
                  12.height,
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: AppColors.secondary2,
                        color: indicatorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
