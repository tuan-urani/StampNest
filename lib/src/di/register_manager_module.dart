import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stamp_camera/src/utils/app_shared.dart';

Future<void> registerManagerModule() async {
  if (!Get.isRegistered<AppShared>()) {
    Get.put<AppShared>(
      AppShared(Get.find<SharedPreferences>()),
      permanent: true,
    );
  }
}
