import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class AppSuccessState extends StatelessWidget {
  const AppSuccessState({
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onActionPressed,
    this.backgroundColor = AppColors.background,
    this.badgeColor = AppColors.secondary2,
    this.iconColor = AppColors.success,
    this.icon = Icons.check_rounded,
    this.maxWidth = 360,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color backgroundColor;
  final Color badgeColor;
  final Color iconColor;
  final IconData icon;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool hasAction = onActionPressed != null;
    final String resolvedActionLabel =
        actionLabel ?? LocaleKey.continueAction.tr;
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
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: Icon(icon, color: iconColor, size: 44),
                    ),
                  ),
                  18.height,
                  Text(
                    title ?? LocaleKey.success.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.h4(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  10.height,
                  Text(
                    message ?? LocaleKey.ready.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyLarge(
                      color: AppColors.stampverseMutedText,
                      height: 1.3,
                    ),
                  ),
                  if (hasAction) ...<Widget>[
                    24.height,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onActionPressed,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          textStyle: AppStyles.buttonLarge(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(resolvedActionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
