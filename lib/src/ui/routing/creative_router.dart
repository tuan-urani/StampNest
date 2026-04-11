import 'package:flutter/cupertino.dart';

import 'package:stamp_camera/src/ui/creative/creative_page.dart';
import 'package:stamp_camera/src/ui/edit_board/edit_board_page.dart';
import 'package:stamp_camera/src/ui/edit_create/edit_create_page.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';

class CreativeRouter {
  static const String root = '/';
  static const String editCreate = '/edit-create';
  static const String editBoard = '/edit-board';

  static String currentRoute = root;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? root;
    currentRoute = routeName;

    switch (routeName) {
      case root:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const CreativePage(),
        );
      case editCreate:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const EditCreatePage(),
        );
      case editBoard:
        final EditBoardPageArgs args = resolveEditBoardPageArgs(
          settings.arguments,
        );
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => EditBoardPage(args: args),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
