import 'package:flutter/cupertino.dart';

import 'package:stamp_camera/src/ui/camera/camera_page.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/save_stamp/save_stamp_page.dart';
import 'package:stamp_camera/src/ui/stamp/stamp_page.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';

class StampRouter {
  static const String root = '/';
  static const String camera = '/camera';
  static const String saveStamp = '/save-stamp';
  static const String stampDetails = '/stamp-details';

  static String currentRoute = root;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? root;
    currentRoute = routeName;

    switch (routeName) {
      case root:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const StampPage(),
        );
      case camera:
        final CameraPageArgs args = resolveCameraPageArgs(settings.arguments);
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => CameraPage(args: args),
        );
      case saveStamp:
        final SaveStampPageArgs args = resolveSaveStampPageArgs(
          settings.arguments,
        );
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => SaveStampPage(args: args),
        );
      case stampDetails:
        final StampDetailsPageArgs args = resolveStampDetailsPageArgs(
          settings.arguments,
        );
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => StampDetailsPage(args: args),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
