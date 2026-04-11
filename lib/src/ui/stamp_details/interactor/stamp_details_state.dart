import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class StampDetailsState extends Equatable {
  const StampDetailsState({
    this.stamp,
    this.isDeleting = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory StampDetailsState.initial() {
    return const StampDetailsState();
  }

  final StampDataModel? stamp;
  final bool isDeleting;
  final String? errorMessage;
  final bool isInitialized;

  StampDetailsState copyWith({
    Object? stamp = _sentinel,
    bool? isDeleting,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return StampDetailsState(
      stamp: stamp == _sentinel ? this.stamp : stamp as StampDataModel?,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    stamp,
    isDeleting,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
