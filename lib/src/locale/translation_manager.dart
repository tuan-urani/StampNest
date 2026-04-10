import 'dart:ui';

import 'package:get/get.dart';

import 'lang_en.dart';
import 'lang_ja.dart';
import 'lang_vi.dart';

class TranslationManager extends Translations {
  static const Locale defaultLocale = Locale('vi', 'VN');
  static const Locale fallbackLocale = Locale('en', 'US');
  static const List<Locale> appLocales = <Locale>[
    Locale('vi', 'VN'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ];

  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'vi_VN': viVn,
    'en_US': enUs,
    'ja_JP': jaJp,
  };
}
