import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';
import 'package:stamp_camera/src/ui/main/components/app_bottom_navigation_bar.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class _TestMainBloc extends MainBloc {
  int popToRootCalls = 0;
  BottomNavigationPage? lastPopPage;

  @override
  void popToRoot(BottomNavigationPage page) {
    popToRootCalls += 1;
    lastPopPage = page;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  Future<_TestMainBloc> pumpBottomBar(WidgetTester tester) async {
    final _TestMainBloc bloc = _TestMainBloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          bottomNavigationBar: BlocProvider<MainBloc>.value(
            value: bloc,
            child: const AppBottomNavigationBar(),
          ),
        ),
      ),
    );
    await tester.pump();
    return bloc;
  }

  testWidgets('renders active and inactive tab styles', (
    WidgetTester tester,
  ) async {
    await pumpBottomBar(tester);

    final Icon stampIcon = tester.widget<Icon>(
      find.byIcon(Icons.style_outlined),
    );
    final Icon collectionIcon = tester.widget<Icon>(
      find.byIcon(Icons.collections_bookmark_outlined),
    );

    expect(stampIcon.color, AppColors.stampverseHeadingText);
    expect(collectionIcon.color, AppColors.stampversePrimaryText);
  });

  testWidgets('changes selected tab when tapping another tab', (
    WidgetTester tester,
  ) async {
    final _TestMainBloc bloc = await pumpBottomBar(tester);

    await tester.tap(find.byIcon(Icons.collections_bookmark_outlined));
    await tester.pump();

    expect(bloc.state.currentPage, BottomNavigationPage.collection);
  });

  testWidgets('pops current tab stack when tapping active tab', (
    WidgetTester tester,
  ) async {
    final _TestMainBloc bloc = await pumpBottomBar(tester);

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();

    expect(bloc.popToRootCalls, 1);
    expect(bloc.lastPopPage, BottomNavigationPage.stamp);
    expect(bloc.state.currentPage, BottomNavigationPage.stamp);
  });
}
