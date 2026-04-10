import 'package:flutter/material.dart';
import 'package:stamp_camera/src/extensions/color_extension.dart';
import 'package:stamp_camera/src/ui/widgets/custom_circular_progress.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class LoadingFullScreen extends StatelessWidget {
  final Widget child;
  final bool loading;
  final Color? backgroundColor;

  const LoadingFullScreen({
    super.key,
    required this.child,
    this.loading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) async => !loading,
      child: Stack(
        children: <Widget>[
          child,
          loading
              ? GestureDetector(
                  onTap: () {},
                  child: Container(
                    color: backgroundColor ?? AppColors.black.withOpacityX(54),
                    constraints: const BoxConstraints.expand(),
                    child: const Center(child: CustomCircularProgress()),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
