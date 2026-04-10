import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/main.dart';
import 'package:stamp_camera/src/di/di_graph_setup.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await setupDependenciesGraph();
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
