import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class CalendarPageState extends Equatable {
  const CalendarPageState({
    required this.stamps,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory CalendarPageState.initial() {
    return const CalendarPageState(stamps: <StampDataModel>[]);
  }

  final List<StampDataModel> stamps;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  CalendarPageState copyWith({
    List<StampDataModel>? stamps,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return CalendarPageState(
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
