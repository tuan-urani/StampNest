import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_event.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final List<GlobalKey<NavigatorState>> tabNavKeys =
      List<GlobalKey<NavigatorState>>.generate(
        BottomNavigationPage.values.length,
        (_) => GlobalKey<NavigatorState>(),
      );

  MainBloc() : super(const MainState()) {
    on<MainInitialized>(_onInitialized);
    on<OnChangeTabEvent>(_onChangeTab);
  }

  GlobalKey<NavigatorState> navigatorKeyOf(BottomNavigationPage page) {
    return tabNavKeys[page.index];
  }

  NavigatorState? navigatorStateOf(BottomNavigationPage page) {
    return navigatorKeyOf(page).currentState;
  }

  bool canPop(BottomNavigationPage page) {
    return navigatorStateOf(page)?.canPop() ?? false;
  }

  void popToRoot(BottomNavigationPage page) {
    final NavigatorState? navigatorState = navigatorStateOf(page);
    if (navigatorState == null) return;
    navigatorState.popUntil((Route<dynamic> route) => route.isFirst);
  }

  void _onInitialized(MainInitialized event, Emitter<MainState> emit) {
    if (state.currentPage == BottomNavigationPage.stamp) return;
    emit(state.copyWith(currentPage: BottomNavigationPage.stamp));
  }

  void _onChangeTab(OnChangeTabEvent event, Emitter<MainState> emit) {
    if (event.page == state.currentPage) return;
    emit(state.copyWith(currentPage: event.page));
  }
}
