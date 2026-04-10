import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/stampverse/interactor/stampverse_bloc.dart';

class StampverseBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StampverseBloc>()) {
      Get.lazyPut<StampverseBloc>(
        () => StampverseBloc(
          repository: Get.find<StampverseRepository>(),
          imagePicker: ImagePicker(),
        ),
      );
    }
  }
}
