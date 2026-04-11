import 'package:flutter/material.dart';

import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseIconButton extends StatelessWidget {
  const StampverseIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconSize = 24,
    this.iconColor = AppColors.stampversePrimaryText,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stampverseSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.stampverseShadowMedium,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
