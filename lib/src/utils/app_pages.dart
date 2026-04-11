import 'package:get/get.dart';

import 'package:stamp_camera/src/ui/album/album_page.dart';
import 'package:stamp_camera/src/ui/camera/camera_page.dart';
import 'package:stamp_camera/src/ui/edit_board/edit_board_page.dart';
import 'package:stamp_camera/src/ui/edit_create/edit_create_page.dart';
import 'package:stamp_camera/src/ui/home/home_page.dart';
import 'package:stamp_camera/src/ui/login/login_page.dart';
import 'package:stamp_camera/src/ui/main/binding/main_binding.dart';
import 'package:stamp_camera/src/ui/main/main_page.dart';
import 'package:stamp_camera/src/ui/register/register_page.dart';
import 'package:stamp_camera/src/ui/save_stamp/save_stamp_page.dart';
import 'package:stamp_camera/src/ui/settings/settings_page.dart';
import 'package:stamp_camera/src/ui/splash/splash_page.dart';
import 'package:stamp_camera/src/ui/stamp/stamp_page.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';
  static const String stampverse = '/stampverse';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';
  static const String camera = '/camera';
  static const String saveStamp = '/save-stamp';
  static const String stampDetails = '/stamp-details';
  static const String album = '/album';
  static const String editCreate = '/edit-create';
  static const String editBoard = '/edit-board';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: main, page: () => const MainPage(), binding: MainBinding()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: stampverse, page: () => const StampPage()),
    GetPage(name: settings, page: () => const SettingsPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: register, page: () => const RegisterPage()),
    GetPage(
      name: camera,
      page: () => CameraPage(args: resolveCameraPageArgs(Get.arguments)),
      opaque: true,
      transition: Transition.noTransition,
      fullscreenDialog: true,
    ),
    GetPage(
      name: saveStamp,
      page: () => SaveStampPage(args: resolveSaveStampPageArgs(Get.arguments)),
    ),
    GetPage(
      name: stampDetails,
      page: () =>
          StampDetailsPage(args: resolveStampDetailsPageArgs(Get.arguments)),
    ),
    GetPage(
      name: album,
      page: () => AlbumPage(args: resolveAlbumPageArgs(Get.arguments)),
    ),
    GetPage(name: editCreate, page: () => const EditCreatePage()),
    GetPage(
      name: editBoard,
      page: () => EditBoardPage(args: resolveEditBoardPageArgs(Get.arguments)),
    ),
  ];
}
