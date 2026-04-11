import 'package:get/get.dart';

import 'package:stamp_camera/src/ui/home/home_page.dart';
import 'package:stamp_camera/src/ui/main/binding/main_binding.dart';
import 'package:stamp_camera/src/ui/main/main_page.dart';
import 'package:stamp_camera/src/ui/splash/splash_page.dart';
import 'package:stamp_camera/src/ui/stamp/stamp_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';
  static const String stampverse = '/stampverse';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: main, page: () => const MainPage(), binding: MainBinding()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: stampverse, page: () => const StampPage()),
  ];
}
