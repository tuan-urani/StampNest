import 'package:flutter/material.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseEmptyTab extends StatelessWidget {
  const StampverseEmptyTab({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final String? actionText = actionLabel;
    final VoidCallback? actionHandler = onActionTap;
    final bool hasAction =
        actionText != null &&
        actionText.trim().isNotEmpty &&
        actionHandler != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.stampverseSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: AppColors.stampverseMutedText),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: StampverseTextStyles.heroTitle(
                color: AppColors.stampverseMutedText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: StampverseTextStyles.body(),
            ),
            if (hasAction) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: Material(
                  color: AppColors.colorF586AA6,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: actionHandler,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text(
                          actionText,
                          style: StampverseTextStyles.body(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
