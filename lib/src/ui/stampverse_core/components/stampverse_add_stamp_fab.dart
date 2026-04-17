import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseAddStampFab extends StatefulWidget {
  const StampverseAddStampFab({
    super.key,
    required this.onOpenCamera,
    required this.onOpenGallery,
  });

  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;

  @override
  State<StampverseAddStampFab> createState() => _StampverseAddStampFabState();
}

class _StampverseAddStampFabState extends State<StampverseAddStampFab> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onSelectAction(VoidCallback action) {
    setState(() {
      _isExpanded = false;
    });
    action();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<Offset> slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.16),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnimation, child: child),
              );
            },
            child: _isExpanded
                ? Padding(
                    key: const ValueKey<String>('expanded-actions'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _FabActionRow(
                          label: LocaleKey.stampverseHomeAddSourceFile.tr,
                          icon: Icons.image_outlined,
                          onTap: () => _onSelectAction(widget.onOpenGallery),
                        ),
                        const SizedBox(height: 12),
                        _FabActionRow(
                          label: LocaleKey.stampverseHomeAddSourceCamera.tr,
                          icon: Icons.camera_alt_outlined,
                          onTap: () => _onSelectAction(widget.onOpenCamera),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey<String>('collapsed-actions'),
                  ),
          ),
          _FabCircleButton(
            size: 60,
            onTap: _toggleExpanded,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isExpanded
                  ? const Icon(
                      Icons.close_rounded,
                      key: ValueKey<String>('close-icon'),
                      size: 34,
                      color: AppColors.white,
                    )
                  : Image.asset(
                      AppAssets.iconsCameraAnimePng,
                      key: const ValueKey<String>('camera-icon'),
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      color: AppColors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabActionRow extends StatelessWidget {
  const _FabActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.stampverseShadowStrong,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              label,
              style: StampverseTextStyles.caption(
                color: AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _FabCircleButton(
          size: 56,
          onTap: onTap,
          child: Icon(icon, size: 24, color: AppColors.white),
        ),
      ],
    );
  }
}

class _FabCircleButton extends StatelessWidget {
  const _FabCircleButton({
    required this.size,
    required this.onTap,
    required this.child,
  });

  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.colorF586AA6,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.stampverseShadowStrong,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
