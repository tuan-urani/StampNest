import 'package:flutter/material.dart';

import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampversePrimaryButton extends StatelessWidget {
  const StampversePrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? handler = enabled ? onTap : null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stampverseSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.stampverseShadowSoft,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: handler,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(label, style: StampverseTextStyles.button()),
                  if (icon != null) ...<Widget>[
                    const SizedBox(width: 10),
                    Icon(
                      icon,
                      size: 20,
                      color: AppColors.stampversePrimaryText,
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
