import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CreativeModeSegment extends StatelessWidget {
  const CreativeModeSegment({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final CreativeViewMode mode;
  final ValueChanged<CreativeViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stampverseBorderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _CreativeSegmentItem(
                label: LocaleKey.stampverseCreativeModeTemplates.tr,
                isSelected: mode == CreativeViewMode.templates,
                onTap: () => onChanged(CreativeViewMode.templates),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CreativeSegmentItem(
                label: LocaleKey.stampverseCreativeModeBoards.tr,
                isSelected: mode == CreativeViewMode.boards,
                onTap: () => onChanged(CreativeViewMode.boards),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreativeSegmentItem extends StatelessWidget {
  const _CreativeSegmentItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.colorF586AA6.withValues(alpha: 0.18)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.colorF586AA6
                  : AppColors.stampverseBorderSoft.withValues(alpha: 0.6),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: StampverseTextStyles.caption(
                color: isSelected
                    ? AppColors.colorF586AA6
                    : AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
