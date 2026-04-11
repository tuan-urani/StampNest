import 'package:flutter/cupertino.dart';

import 'package:stamp_camera/src/ui/calendar/calendar_page.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';

class CalendarRouter {
  static const String root = '/';
  static const String stampDetails = '/stamp-details';

  static String currentRoute = root;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? root;
    currentRoute = routeName;

    switch (routeName) {
      case root:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const CalendarPage(),
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
