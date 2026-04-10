import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stamp_camera/src/api/stampverse_api.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';

Future<void> registerCoreModule() async {
  if (!Get.isRegistered<Dio>()) {
    Get.put<Dio>(Dio(), permanent: true);
  }

  if (!Get.isRegistered<SharedPreferences>()) {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(preferences, permanent: true);
  }

  if (!Get.isRegistered<StampverseApi>()) {
    Get.lazyPut<StampverseApi>(
      () => StampverseApi(
        dio: Get.find<Dio>(),
        baseUrl: dotenv.env['API_BASE_URL'],
      ),
      fenix: true,
    );
  }

  if (!Get.isRegistered<StampverseRepository>()) {
    Get.lazyPut<StampverseRepository>(
      () => StampverseRepository(
        api: Get.find<StampverseApi>(),
        preferences: Get.find<SharedPreferences>(),
      ),
      fenix: true,
    );
  }
}
