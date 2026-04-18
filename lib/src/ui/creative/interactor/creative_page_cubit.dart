import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_template_catalog.dart';
import 'package:intl/intl.dart';

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
        templates: creativeTemplateCatalog,
        selectedBoardIds: _sanitizeSelectedBoardIds(
          selectedIds: state.selectedBoardIds,
          boards: boards,
        ),
        isLoading: false,
        isInitialized: true,
      ),
    );
  }

  void changeViewMode(CreativeViewMode mode) {
    if (mode == state.viewMode) return;
    emit(
      state.copyWith(
        viewMode: mode,
        selectedBoardIds: mode == CreativeViewMode.boards
            ? state.selectedBoardIds
            : const <String>[],
      ),
    );
  }

  Future<String?> createBoardFromTemplate({
    required StampEditTemplate template,
    required String templateName,
  }) async {
    final String nowIso = DateTime.now().toIso8601String();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String boardName =
        '$templateName ${DateFormat('dd/MM HH:mm').format(DateTime.now())}';

    final List<StampEditLayer> layers = template.slots
        .map((StampEditTemplateSlot slot) {
          return StampEditLayer(
            id: 'layer_${slot.id}_$timestamp',
            stampId: '',
            imageUrl: '',
            shapeType: StampShapeType.square,
            centerX: slot.centerX,
            centerY: slot.centerY,
            rotation: slot.rotation,
            layerType: StampEditLayerType.templateSlot,
            widthRatio: slot.widthRatio,
            heightRatio: slot.heightRatio,
            frameShape: slot.frameShape,
          );
        })
        .toList(growable: false);

    final StampEditBoard board = StampEditBoard(
      id: 'board_$timestamp',
      name: boardName,
      createdAt: nowIso,
      updatedAt: nowIso,
      layers: layers,
      editorMode: StampEditBoardEditorMode.template,
      templateId: template.id,
      templateBackgroundAssetPath: template.editorBackgroundAssetPath,
      templateCanvasColorHex: template.editorCanvasColorHex,
      templateSourceWidth: template.sourceWidth,
      templateSourceHeight: template.sourceHeight,
    );

    final List<StampEditBoard> boards = await _repository.readEditBoardsCache();
    final List<StampEditBoard> updatedBoards = <StampEditBoard>[
      board,
      ...boards,
    ];
    await _repository.saveEditBoardsCache(updatedBoards);

    emit(
      state.copyWith(
        boards: updatedBoards,
        viewMode: CreativeViewMode.boards,
        selectedBoardIds: const <String>[],
      ),
    );
    return board.id;
  }

  void startEditBoardSelection(String boardId) {
    if (!_hasEditBoard(boardId)) return;
    if (state.selectedBoardIds.contains(boardId)) return;

    emit(
      state.copyWith(
        selectedBoardIds: <String>[boardId],
        errorMessage: null,
        viewMode: CreativeViewMode.boards,
      ),
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
