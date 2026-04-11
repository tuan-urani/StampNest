import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/camera/interactor/camera_page_state.dart';

class CameraPageCubit extends Cubit<CameraPageState> {
  CameraPageCubit({
    String? initialDraftImage,
    StampShapeType initialShape = StampShapeType.scallop,
  }) : super(
         CameraPageState.initial(
           draftImage: initialDraftImage,
           selectedShape: initialShape,
         ),
       );

  void updateShape(StampShapeType shapeType) {
    if (shapeType == state.selectedShape) return;
    emit(state.copyWith(selectedShape: shapeType));
  }

  void resetDraft() {
    emit(state.copyWith(draftImage: null));
  }
}
