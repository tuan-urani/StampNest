import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

/// Placeholder root page for tabs that are not wired to real features yet.
class MainTabPlaceholderPage extends StatelessWidget {
  const MainTabPlaceholderPage({super.key, required this.page});

  final BottomNavigationPage page;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfacePage,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(page.getIcon(true), size: 42, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                page.localeKey.tr,
                style: AppStyles.h4(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
