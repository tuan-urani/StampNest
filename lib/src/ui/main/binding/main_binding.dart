import 'package:get/get.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainBloc>()) {
      Get.lazyPut<MainBloc>(MainBloc.new);
    }
  }
}
