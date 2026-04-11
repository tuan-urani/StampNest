import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_event.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_state.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainBloc, MainState>(
      buildWhen: (previous, current) =>
          previous.currentPage != current.currentPage,
      builder: (context, state) {
        final bloc = context.read<MainBloc>();
        final tabs = BottomNavigationPage.values;
        final currentIndex = tabs.indexOf(state.currentPage);

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.stampverseBorderSoft),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.stampverseShadowStrong,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: _buildItems(
                    tabs: tabs,
                    currentIndex: currentIndex,
                    onChanged: (BottomNavigationPage page) {
                      if (page == state.currentPage) {
                        bloc.popToRoot(page);
                        return;
                      }
                      bloc.add(OnChangeTabEvent(page));
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildItems({
    required List<BottomNavigationPage> tabs,
    required int currentIndex,
    required ValueChanged<BottomNavigationPage> onChanged,
  }) {
    return List.generate(tabs.length, (index) {
      final page = tabs[index];
      final isSelected = currentIndex == index;
      return _TabItem(
        page: page,
        isSelected: isSelected,
        onTap: () => onChanged(page),
      );
    });
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavigationPage page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.stampverseHeadingText
        : AppColors.stampversePrimaryText;

    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
          focusColor: AppColors.transparent,
          hoverColor: AppColors.transparent,
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? AppColors.stampverseBorderSoft : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(page.getIcon(isSelected), size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  page.localeKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StampverseTextStyles.caption(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
