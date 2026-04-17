import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'package:stamp_camera/src/di/di_graph_setup.dart';
import 'package:stamp_camera/src/locale/translation_manager.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_pages.dart';
import 'package:stamp_camera/src/utils/app_shared.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependenciesGraph();
  final AppShared appShared = Get.find<AppShared>();
  final Locale initialLocale = TranslationManager.resolveLocaleFromLanguageCode(
    appShared.getLanguageCode(),
  );
  runApp(App(initialLocale: initialLocale));
}

class App extends StatelessWidget {
  const App({super.key, required this.initialLocale});

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.brandPrimary,
          onPrimary: AppColors.neutral0,
          secondary: AppColors.brandSecondary,
          onSecondary: AppColors.neutral700,
          surface: AppColors.surfaceCard,
          onSurface: AppColors.neutral700,
          error: AppColors.semanticError,
          onError: AppColors.neutral0,
        ),
        scaffoldBackgroundColor: AppColors.surfacePage,
        focusColor: AppColors.stateFocus,
        hoverColor: AppColors.stateHover,
        splashColor: AppColors.statePressed,
        highlightColor: AppColors.statePressed,
        disabledColor: AppColors.stateDisabledText,
        dividerColor: AppColors.borderDefault,
      ),
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: initialLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
      supportedLocales: TranslationManager.appLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate,
      ],
    );
  }
}
