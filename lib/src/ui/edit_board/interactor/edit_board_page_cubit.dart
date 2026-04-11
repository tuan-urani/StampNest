import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/edit_board/interactor/edit_board_page_state.dart';

class EditBoardPageCubit extends Cubit<EditBoardPageState> {
  EditBoardPageCubit({required StampverseRepository repository})
    : _repository = repository,
      super(EditBoardPageState.initial());

  final StampverseRepository _repository;

  String _boardId = '';

  Future<void> initialize({required String boardId}) async {
    _boardId = boardId;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final List<StampEditBoard> boards = await _repository.readEditBoardsCache();
    final List<StampDataModel> stamps = await _repository.readCache();

    emit(
      state.copyWith(
        allBoards: boards,
        stamps: stamps,
        currentBoard: _findBoard(boards, boardId),
        isLoading: false,
        isInitialized: true,
      ),
    );
  }

  Future<void> refresh() async {
    await initialize(boardId: _boardId);
  }

  Future<void> saveBoard(StampEditBoard board) async {
    final String nowIso = DateTime.now().toIso8601String();
    final StampEditBoard nextBoard = board.copyWith(updatedAt: nowIso);

    final List<StampEditBoard> updated = List<StampEditBoard>.from(
      state.allBoards,
    );
    final int currentIndex = updated.indexWhere(
      (StampEditBoard item) => item.id == nextBoard.id,
    );

    if (currentIndex < 0) {
      updated.insert(0, nextBoard);
    } else {
      updated[currentIndex] = nextBoard;
    }

    updated.sort((StampEditBoard a, StampEditBoard b) {
      return b.parsedUpdatedAt.compareTo(a.parsedUpdatedAt);
    });

    await _repository.saveEditBoardsCache(updated);

    emit(
      state.copyWith(
        allBoards: updated,
        currentBoard: _findBoard(updated, nextBoard.id),
      ),
    );
  }

  StampEditBoard? _findBoard(List<StampEditBoard> boards, String boardId) {
    for (final StampEditBoard board in boards) {
      if (board.id == boardId) return board;
    }
    return null;
  }
}
