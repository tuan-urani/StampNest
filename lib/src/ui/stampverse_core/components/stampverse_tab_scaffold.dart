import 'package:flutter/material.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_add_stamp_fab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseTabScaffold extends StatelessWidget {
  const StampverseTabScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.showFab = false,
    this.onOpenCamera,
    this.onOpenGallery,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final bool showFab;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                  child: Row(
                    children: <Widget>[
                      if (leading != null) ...<Widget>[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: StampverseTextStyles.sectionTitle(
                            color: AppColors.stampverseHeadingText,
                          ),
                        ),
                      ),
                      if (trailing case final Widget trailingWidget)
                        trailingWidget,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
            if (showFab && onOpenCamera != null && onOpenGallery != null)
              Positioned(
                right: 26,
                bottom: StampverseLayout.bottomBarReservedSpace,
                child: StampverseAddStampFab(
                  onOpenCamera: onOpenCamera!,
                  onOpenGallery: onOpenGallery!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
