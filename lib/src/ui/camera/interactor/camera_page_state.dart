import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

class CameraPageState extends Equatable {
  const CameraPageState({
    this.draftImage,
    this.selectedShape = StampShapeType.scallop,
  });

  factory CameraPageState.initial({
    String? draftImage,
    StampShapeType selectedShape = StampShapeType.scallop,
  }) {
    return CameraPageState(
      draftImage: draftImage,
      selectedShape: selectedShape,
    );
  }

  final String? draftImage;
  final StampShapeType selectedShape;

  CameraPageState copyWith({
    Object? draftImage = _sentinel,
    StampShapeType? selectedShape,
  }) {
    return CameraPageState(
      draftImage: draftImage == _sentinel
          ? this.draftImage
          : draftImage as String?,
      selectedShape: selectedShape ?? this.selectedShape,
    );
  }

  @override
  List<Object?> get props => <Object?>[draftImage, selectedShape];
}

const Object _sentinel = Object();
