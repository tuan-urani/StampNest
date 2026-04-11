import 'package:flutter/cupertino.dart';

import 'package:stamp_camera/src/ui/album/album_page.dart';
import 'package:stamp_camera/src/ui/collection/collection_page.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';

class CollectionRouter {
  static const String root = '/';
  static const String album = '/album';
  static const String stampDetails = '/stamp-details';

  static String currentRoute = root;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? root;
    currentRoute = routeName;

    switch (routeName) {
      case root:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const CollectionPage(),
        );
      case album:
        final AlbumPageArgs args = resolveAlbumPageArgs(settings.arguments);
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => AlbumPage(args: args),
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
