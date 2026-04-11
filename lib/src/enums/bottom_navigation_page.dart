import 'package:flutter/material.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';

enum BottomNavigationPage { stamp, collection, creative, calendar }

extension BottomNavigationPageExtension on BottomNavigationPage {
  String get localeKey {
    switch (this) {
      case BottomNavigationPage.stamp:
        return LocaleKey.stampverseHomeTabStamp;
      case BottomNavigationPage.collection:
        return LocaleKey.stampverseHomeTabCollection;
      case BottomNavigationPage.creative:
        return LocaleKey.stampverseHomeTabEdit;
      case BottomNavigationPage.calendar:
        return LocaleKey.stampverseHomeTabMemory;
    }
  }

  IconData get icon {
    switch (this) {
      case BottomNavigationPage.stamp:
        return Icons.style_outlined;
      case BottomNavigationPage.collection:
        return Icons.collections_bookmark_outlined;
      case BottomNavigationPage.creative:
        return Icons.edit_rounded;
      case BottomNavigationPage.calendar:
        return Icons.history_rounded;
    }
  }

  IconData getIcon(bool isSelected) => icon;
}
