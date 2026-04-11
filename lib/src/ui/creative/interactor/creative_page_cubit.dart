import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';

class CreativePageCubit extends Cubit<CreativePageState> {
  CreativePageCubit({required StampverseRepository repository})
    : _repository = repository,
      super(CreativePageState.initial());

  final StampverseRepository _repository;

  Future<void> initialize() async {
    if (state.isInitialized) return;
    await refresh(initialLoad: true);
  }

  Future<void> refresh({bool initialLoad = false}) async {
    emit(state.copyWith(isLoading: initialLoad, errorMessage: null));

    final List<StampEditBoard> boards = await _repository.readEditBoardsCache();
    emit(
      state.copyWith(
        boards: boards,
        selectedBoardIds: _sanitizeSelectedBoardIds(
          selectedIds: state.selectedBoardIds,
          boards: boards,
        ),
        isLoading: false,
        isInitialized: true,
      ),
    );
  }

  void startEditBoardSelection(String boardId) {
    if (!_hasEditBoard(boardId)) return;
    if (state.selectedBoardIds.contains(boardId)) return;

    emit(
      state.copyWith(selectedBoardIds: <String>[boardId], errorMessage: null),
    );
  }

  void toggleEditBoardSelection(String boardId) {
    if (!_hasEditBoard(boardId)) return;

    final Set<String> nextSelection = state.selectedBoardIds.toSet();
    if (nextSelection.contains(boardId)) {
      nextSelection.remove(boardId);
    } else {
      nextSelection.add(boardId);
    }

    emit(
      state.copyWith(
        selectedBoardIds: _sanitizeSelectedBoardIds(
          selectedIds: nextSelection.toList(),
          boards: state.boards,
        ),
      ),
    );
  }

  void clearEditBoardSelection() {
    if (state.selectedBoardIds.isEmpty) return;
    emit(state.copyWith(selectedBoardIds: const <String>[]));
  }

  Future<void> deleteSelectedEditBoards() async {
    final List<String> selectedIds = _sanitizeSelectedBoardIds(
      selectedIds: state.selectedBoardIds,
      boards: state.boards,
    );
    if (selectedIds.isEmpty) return;

    final Set<String> selectedSet = selectedIds.toSet();
    final List<StampEditBoard> updatedBoards = state.boards
        .where((StampEditBoard board) => !selectedSet.contains(board.id))
        .toList(growable: false);

    await _repository.saveEditBoardsCache(updatedBoards);
    emit(
      state.copyWith(
        boards: updatedBoards,
        selectedBoardIds: const <String>[],
        errorMessage: null,
      ),
    );
  }

  bool _hasEditBoard(String boardId) {
    return state.boards.any((StampEditBoard board) => board.id == boardId);
  }

  List<String> _sanitizeSelectedBoardIds({
    required List<String> selectedIds,
    required List<StampEditBoard> boards,
  }) {
    final Set<String> existingIds = boards
        .map((StampEditBoard board) => board.id)
        .toSet();
    return selectedIds
        .where((String id) => existingIds.contains(id))
        .toSet()
        .toList(growable: false);
  }
}
