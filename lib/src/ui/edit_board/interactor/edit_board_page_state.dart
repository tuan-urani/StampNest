import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';

class EditBoardPageState extends Equatable {
  const EditBoardPageState({
    required this.allBoards,
    required this.stamps,
    this.currentBoard,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory EditBoardPageState.initial() {
    return const EditBoardPageState(
      allBoards: <StampEditBoard>[],
      stamps: <StampDataModel>[],
    );
  }

  final List<StampEditBoard> allBoards;
  final List<StampDataModel> stamps;
  final StampEditBoard? currentBoard;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  EditBoardPageState copyWith({
    List<StampEditBoard>? allBoards,
    List<StampDataModel>? stamps,
    Object? currentBoard = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return EditBoardPageState(
      allBoards: allBoards ?? this.allBoards,
      stamps: stamps ?? this.stamps,
      currentBoard: currentBoard == _sentinel
          ? this.currentBoard
          : currentBoard as StampEditBoard?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    allBoards,
    stamps,
    currentBoard,
    isLoading,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
