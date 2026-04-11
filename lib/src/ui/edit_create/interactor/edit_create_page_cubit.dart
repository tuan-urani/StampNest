import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/edit_create/interactor/edit_create_page_state.dart';

class EditCreatePageCubit extends Cubit<EditCreatePageState> {
  EditCreatePageCubit({required StampverseRepository repository})
    : _repository = repository,
      super(const EditCreatePageState());

  final StampverseRepository _repository;

  Future<String?> createEditBoardFromName(String rawName) async {
    final String trimmedName = rawName.trim();
    if (trimmedName.isEmpty) return null;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    final String nowIso = DateTime.now().toIso8601String();
    final StampEditBoard board = _createDefaultBoard(
      name: trimmedName,
      nowIso: nowIso,
    );

    final List<StampEditBoard> boards = await _repository.readEditBoardsCache();
    final List<StampEditBoard> updatedBoards = <StampEditBoard>[
      board,
      ...boards,
    ];
    await _repository.saveEditBoardsCache(updatedBoards);

    emit(state.copyWith(isSaving: false, errorMessage: null));
    return board.id;
  }

  StampEditBoard _createDefaultBoard({
    required String name,
    required String nowIso,
  }) {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return StampEditBoard(
      id: 'board_$timestamp',
      name: name,
      createdAt: nowIso,
      updatedAt: nowIso,
      layers: const <StampEditLayer>[],
    );
  }
}
