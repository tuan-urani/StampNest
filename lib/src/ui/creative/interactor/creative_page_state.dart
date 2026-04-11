import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';

class CreativePageState extends Equatable {
  const CreativePageState({
    required this.boards,
    this.selectedBoardIds = const <String>[],
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory CreativePageState.initial() {
    return const CreativePageState(boards: <StampEditBoard>[]);
  }

  final List<StampEditBoard> boards;
  final List<String> selectedBoardIds;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  CreativePageState copyWith({
    List<StampEditBoard>? boards,
    List<String>? selectedBoardIds,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return CreativePageState(
      boards: boards ?? this.boards,
      selectedBoardIds: selectedBoardIds ?? this.selectedBoardIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    boards,
    selectedBoardIds,
    isLoading,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
