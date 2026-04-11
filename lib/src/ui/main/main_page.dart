import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_event.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_state.dart';
import 'package:stamp_camera/src/ui/main/components/app_bottom_navigation_bar.dart';
import 'package:stamp_camera/src/ui/routing/calendar_router.dart';
import 'package:stamp_camera/src/ui/routing/collection_router.dart';
import 'package:stamp_camera/src/ui/routing/creative_router.dart';
import 'package:stamp_camera/src/ui/routing/stamp_router.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final MainBloc _bloc;
  final Map<BottomNavigationPage, Widget> _pages =
      <BottomNavigationPage, Widget>{};

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<MainBloc>();
    _bloc.add(const MainInitialized());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainBloc>.value(
      value: _bloc,
      child: BlocBuilder<MainBloc, MainState>(
        buildWhen: (previous, current) =>
            previous.currentPage != current.currentPage,
        builder: (context, state) {
          final List<BottomNavigationPage> tabs = BottomNavigationPage.values;
          final int currentIndex = tabs.indexOf(state.currentPage);

          final int safeIndex = currentIndex < 0 ? 0 : currentIndex;
          return Scaffold(
            backgroundColor: AppColors.transparent,
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: IndexedStack(
              sizing: StackFit.expand,
              index: safeIndex,
              children: tabs
                  .map((BottomNavigationPage page) => _createPage(page: page))
                  .toList(),
            ),
            bottomNavigationBar: const AppBottomNavigationBar(),
          );
        },
      ),
    );
  }

  Widget _createPage({required BottomNavigationPage page}) {
    return _pages.putIfAbsent(page, () {
      return CupertinoTabView(
        navigatorKey: _bloc.navigatorKeyOf(page),
        onGenerateRoute: (RouteSettings settings) {
          return _onGenerateRoute(page: page, settings: settings);
        },
      );
    });
  }

  Route<dynamic>? _onGenerateRoute({
    required BottomNavigationPage page,
    required RouteSettings settings,
  }) {
    switch (page) {
      case BottomNavigationPage.stamp:
        return StampRouter.onGenerateRoute(settings);
      case BottomNavigationPage.collection:
        return CollectionRouter.onGenerateRoute(settings);
      case BottomNavigationPage.creative:
        return CreativeRouter.onGenerateRoute(settings);
      case BottomNavigationPage.calendar:
        return CalendarRouter.onGenerateRoute(settings);
    }
  }
}
