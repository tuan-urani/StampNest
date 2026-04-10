import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/main.dart';
import 'package:stamp_camera/src/di/di_graph_setup.dart';
import 'package:stamp_camera/src/locale/translation_manager.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await setupDependenciesGraph();
    await tester.pumpWidget(
      const App(initialLocale: TranslationManager.defaultLocale),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
