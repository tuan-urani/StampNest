import 'package:flutter/material.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseTopRoundActionButton extends StatelessWidget {
  const StampverseTopRoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.stampversePrimaryText,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
