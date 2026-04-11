import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class CollectionPageState extends Equatable {
  const CollectionPageState({
    required this.stamps,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory CollectionPageState.initial() {
    return const CollectionPageState(stamps: <StampDataModel>[]);
  }

  final List<StampDataModel> stamps;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  CollectionPageState copyWith({
    List<StampDataModel>? stamps,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return CollectionPageState(
      stamps: stamps ?? this.stamps,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    stamps,
    isLoading,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
