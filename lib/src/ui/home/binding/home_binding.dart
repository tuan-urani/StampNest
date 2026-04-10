import 'package:get/get.dart';

import 'package:stamp_camera/src/ui/home/bloc/home_bloc.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeBloc>()) {
      Get.lazyPut<HomeBloc>(HomeBloc.new);
    }
  }
}
