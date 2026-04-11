import 'package:flutter/cupertino.dart';

import 'package:stamp_camera/src/ui/login/login_page.dart';
import 'package:stamp_camera/src/ui/register/register_page.dart';
import 'package:stamp_camera/src/ui/settings/settings_page.dart';

class CommonRouter {
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settingsData) {
    switch (settingsData.name) {
      case settings:
        return CupertinoPageRoute<void>(
          settings: settingsData,
          builder: (_) => const SettingsPage(),
        );
      case login:
        return CupertinoPageRoute<void>(
          settings: settingsData,
          builder: (_) => const LoginPage(),
        );
      case register:
        return CupertinoPageRoute<void>(
          settings: settingsData,
          builder: (_) => const RegisterPage(),
        );
      default:
        return CupertinoPageRoute<void>(
          settings: settingsData,
          builder: (_) => const SizedBox.shrink(),
        );
    }
  }
}
