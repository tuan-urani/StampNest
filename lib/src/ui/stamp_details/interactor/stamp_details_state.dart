import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class StampDetailsState extends Equatable {
  const StampDetailsState({
    this.stamp,
    this.collections = const <String>[],
    this.isDeleting = false,
    this.isAssigningCollection = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory StampDetailsState.initial() {
    return const StampDetailsState();
  }

  final StampDataModel? stamp;
  final List<String> collections;
  final bool isDeleting;
  final bool isAssigningCollection;
  final String? errorMessage;
  final bool isInitialized;

  StampDetailsState copyWith({
    Object? stamp = _sentinel,
    List<String>? collections,
    bool? isDeleting,
    bool? isAssigningCollection,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return StampDetailsState(
      stamp: stamp == _sentinel ? this.stamp : stamp as StampDataModel?,
      collections: collections ?? this.collections,
      isDeleting: isDeleting ?? this.isDeleting,
      isAssigningCollection:
          isAssigningCollection ?? this.isAssigningCollection,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    stamp,
    collections,
    isDeleting,
    isAssigningCollection,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
