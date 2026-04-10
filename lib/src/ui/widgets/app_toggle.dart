import 'package:flutter/material.dart';
import 'package:stamp_camera/src/extensions/int_extensions.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final double padding = 2;
    final double thumbSize = height - padding * 2;

    final BoxDecoration decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      gradient: value
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
            )
          : null,
      color: value ? null : AppColors.stateDisabledBackground,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: 2.paddingAll,
          decoration: decoration,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.stampverseShadowStrong,
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: AppColors.stampverseShadowStrong,
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -4,
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
