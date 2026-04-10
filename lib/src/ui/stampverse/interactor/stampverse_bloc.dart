import 'dart:convert';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';

import 'stampverse_state.dart';

class StampverseBloc extends Cubit<StampverseState> {
  StampverseBloc({
    required StampverseRepository repository,
    required ImagePicker imagePicker,
  }) : _repository = repository,
       _imagePicker = imagePicker,
       super(StampverseState.initial());

  final StampverseRepository _repository;
  final ImagePicker _imagePicker;

  Future<void> initialize() async {
    if (state.isInitialized) return;

    final List<StampDataModel> cachedStamps = await _repository.readCache();
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(cachedStamps);
    final List<StampEditBoard> cachedBoards = await _repository
        .readEditBoardsCache();
    final String? activeBoardId = cachedBoards.isEmpty
        ? null
        : cachedBoards.first.id;

    emit(
      state.copyWith(
        stamps: cachedStamps,
        collections: collections,
        editBoards: cachedBoards,
        activeEditBoardId: activeBoardId,
        authToken: null,
        user: null,
        view: StampverseView.home,
        isInitialized: true,
      ),
    );
  }

  Future<void> syncStamps() async {
    emit(state.copyWith(isSyncing: true, errorMessage: null));

    final List<StampDataModel> cachedStamps = await _repository.readCache();
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(cachedStamps);

    emit(
      state.copyWith(
        stamps: cachedStamps,
        collections: collections,
        isSyncing: false,
        errorMessage: null,
      ),
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    emit(state.copyWith(errorMessage: null));
  }

  void openRegister() {
    openHome();
  }

  void openLogin() {
    openHome();
  }

  void openHome({StampverseHomeTab? tab}) {
    emit(
      state.copyWith(
        view: StampverseView.home,
        homeTab: tab ?? state.homeTab,
        activeCollection: null,
        errorMessage: null,
      ),
    );
  }

  void changeHomeTab(StampverseHomeTab tab) {
    if (tab == state.homeTab && state.view == StampverseView.home) return;
    emit(
      state.copyWith(
        homeTab: tab,
        view: StampverseView.home,
        activeCollection: null,
        errorMessage: null,
      ),
    );
  }

  void openAlbum() {
    changeHomeTab(StampverseHomeTab.collection);
  }

  void openEditBoardCreate() {
    emit(
      state.copyWith(
        view: StampverseView.editCreate,
        homeTab: StampverseHomeTab.edit,
        activeCollection: null,
        errorMessage: null,
      ),
    );
  }

  void createEditBoardFromName(String rawName) {
    final String nowIso = DateTime.now().toIso8601String();
    final String trimmedName = rawName.trim();
    final String boardName = trimmedName.isEmpty
        ? 'Draft${state.editBoards.length + 1}'
        : trimmedName;
    final StampEditBoard board = _createDefaultBoard(
      name: boardName,
      nowIso: nowIso,
    );
    final List<StampEditBoard> updated = <StampEditBoard>[
      board,
      ...state.editBoards,
    ];
    emit(
      state.copyWith(
        editBoards: updated,
        activeEditBoardId: board.id,
        view: StampverseView.home,
        homeTab: StampverseHomeTab.edit,
        activeCollection: null,
      ),
    );
    unawaited(_repository.saveEditBoardsCache(updated));
  }

  void openEditBoard(String boardId) {
    final bool exists = state.editBoards.any(
      (StampEditBoard board) => board.id == boardId,
    );
    if (!exists) return;

    emit(
      state.copyWith(
        activeEditBoardId: boardId,
        view: StampverseView.editBoard,
        homeTab: StampverseHomeTab.edit,
        activeCollection: null,
        errorMessage: null,
      ),
    );
  }

  void selectEditBoard(String boardId) {
    final bool exists = state.editBoards.any(
      (StampEditBoard board) => board.id == boardId,
    );
    if (!exists) return;
    emit(state.copyWith(activeEditBoardId: boardId));
  }

  void saveEditBoard(StampEditBoard board) {
    final String nowIso = DateTime.now().toIso8601String();
    final StampEditBoard nextBoard = board.copyWith(updatedAt: nowIso);

    final int currentIndex = state.editBoards.indexWhere(
      (StampEditBoard item) => item.id == nextBoard.id,
    );

    final List<StampEditBoard> updated = List<StampEditBoard>.from(
      state.editBoards,
    );
    if (currentIndex < 0) {
      updated.insert(0, nextBoard);
    } else {
      updated[currentIndex] = nextBoard;
    }

    updated.sort((StampEditBoard a, StampEditBoard b) {
      return b.parsedUpdatedAt.compareTo(a.parsedUpdatedAt);
    });

    emit(state.copyWith(editBoards: updated, activeEditBoardId: nextBoard.id));
    unawaited(_repository.saveEditBoardsCache(updated));
  }

  void openCollectionAlbum(String collectionName) {
    final String normalized = collectionName.trim();
    if (normalized.isEmpty) {
      changeHomeTab(StampverseHomeTab.collection);
      return;
    }

    emit(
      state.copyWith(
        view: StampverseView.album,
        activeCollection: normalized,
        errorMessage: null,
      ),
    );
  }

  void openCamera() {
    emit(
      state.copyWith(
        view: StampverseView.camera,
        cameraDraftImage: null,
        isLiveCameraActive: true,
        errorMessage: null,
      ),
    );
  }

  void updateCameraShape(StampShapeType shapeType) {
    if (shapeType == state.cameraShape) return;
    emit(state.copyWith(cameraShape: shapeType));
  }

  void activateLiveCamera() {
    emit(state.copyWith(isLiveCameraActive: true, errorMessage: null));
  }

  void deactivateLiveCamera() {
    if (!state.isLiveCameraActive) return;
    emit(state.copyWith(isLiveCameraActive: false));
  }

  void selectStamp(String id) {
    final int index = state.stamps.indexWhere(
      (StampDataModel item) => item.id == id,
    );
    if (index < 0) return;

    final StampDataModel selected = state.stamps[index];
    final String openedAt = DateTime.now().toIso8601String();
    final List<StampDataModel> updated = List<StampDataModel>.from(
      state.stamps,
    );
    updated[index] = selected.copyWith(lastOpenedAt: openedAt);

    emit(
      state.copyWith(
        stamps: updated,
        selectedStampId: id,
        activeCollection: state.activeCollection,
        view: StampverseView.details,
        showDeleteConfirm: false,
      ),
    );

    unawaited(_repository.saveCache(updated));
  }

  void toggleFavoriteStamp(String id) {
    final int index = state.stamps.indexWhere(
      (StampDataModel item) => item.id == id,
    );
    if (index < 0) return;

    final StampDataModel selected = state.stamps[index];
    final List<StampDataModel> updated = List<StampDataModel>.from(
      state.stamps,
    );
    updated[index] = selected.copyWith(isFavorite: !selected.isFavorite);

    emit(state.copyWith(stamps: updated));
    unawaited(_repository.saveCache(updated));
  }

  void showDeleteConfirm(bool value) {
    emit(state.copyWith(showDeleteConfirm: value));
  }

  void resetCameraDraft() {
    if (state.cameraDraftImage == null) return;
    emit(state.copyWith(cameraDraftImage: null, isLiveCameraActive: true));
  }

  void setCameraDraftImage(String imageDataUrl) {
    emit(
      state.copyWith(
        cameraDraftImage: imageDataUrl,
        isLiveCameraActive: false,
        errorMessage: null,
      ),
    );
  }

  void captureLiveAndOpenSave(String imageDataUrl) {
    emit(
      state.copyWith(
        currentCapture: imageDataUrl,
        currentCaptureShape: state.cameraShape,
        cameraDraftImage: null,
        isLiveCameraActive: false,
        view: StampverseView.save,
        errorMessage: null,
      ),
    );
  }

  void confirmCrop(String croppedImageDataUrl) {
    final String draft = croppedImageDataUrl.trim();
    if (draft.isEmpty) return;

    emit(
      state.copyWith(
        currentCapture: draft,
        currentCaptureShape: state.cameraShape,
        view: StampverseView.save,
        isLiveCameraActive: false,
        errorMessage: null,
      ),
    );
  }

  void back() {
    final StampverseView view = state.view;

    switch (view) {
      case StampverseView.save:
        emit(
          state.copyWith(
            view: StampverseView.camera,
            cameraDraftImage: null,
            isLiveCameraActive: true,
          ),
        );
        return;
      case StampverseView.details:
        final String? activeCollection = state.activeCollection;
        emit(
          state.copyWith(
            view: activeCollection == null || activeCollection.isEmpty
                ? StampverseView.home
                : StampverseView.album,
            selectedStampId: null,
            showDeleteConfirm: false,
          ),
        );
        return;
      case StampverseView.register:
        openHome();
        return;
      case StampverseView.camera:
        openHome();
        return;
      case StampverseView.album:
        openHome(tab: StampverseHomeTab.collection);
        return;
      case StampverseView.editCreate:
      case StampverseView.editBoard:
        openHome(tab: StampverseHomeTab.edit);
        return;
      case StampverseView.home:
      case StampverseView.login:
        openHome(tab: state.homeTab);
        return;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    openHome();
  }

  Future<void> register({
    required String username,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    openHome();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (file == null) return;

      final String mimeType = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpeg';
      final List<int> bytes = await file.readAsBytes();
      final String encoded = base64Encode(bytes);
      final String dataUrl = 'data:image/$mimeType;base64,$encoded';

      emit(
        state.copyWith(
          view: StampverseView.camera,
          cameraDraftImage: dataUrl,
          isLiveCameraActive: false,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(errorMessage: 'CAMERA_PERMISSION_ERROR'));
    }
  }

  Future<void> saveStamp({
    required String rawName,
    required String rawCollection,
  }) async {
    final String? imageUrl = state.currentCapture;
    if (imageUrl == null || imageUrl.isEmpty) return;

    final String stampName = rawName.trim();
    final String collectionName = rawCollection.trim();
    final StampShapeType shapeType = state.currentCaptureShape;
    final String dateIso = DateTime.now().toIso8601String();
    final StampDataModel optimisticStamp = StampDataModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: stampName,
      imageUrl: imageUrl,
      date: dateIso,
      shapeType: shapeType,
      album: collectionName.isEmpty ? null : collectionName,
      lastOpenedAt: dateIso,
    );
    final List<StampDataModel> optimisticList = <StampDataModel>[
      optimisticStamp,
      ...state.stamps,
    ];
    final List<String> optimisticCollections = collectionName.isEmpty
        ? await _repository.mergeCollectionsWithStamps(optimisticList)
        : await _repository.addCollection(collectionName);

    emit(
      state.copyWith(
        isSaving: true,
        stamps: optimisticList,
        collections: optimisticCollections,
        view: StampverseView.home,
        homeTab: StampverseHomeTab.stamp,
        currentCapture: null,
        currentCaptureShape: state.cameraShape,
        cameraDraftImage: null,
        isLiveCameraActive: false,
        errorMessage: null,
      ),
    );

    await _repository.saveCache(optimisticList);
    emit(state.copyWith(isSaving: false));
  }

  Future<void> deleteSelectedStamp() async {
    final String? id = state.selectedStampId;
    if (id == null || id.isEmpty) return;

    emit(state.copyWith(isDeleting: true, errorMessage: null));

    final List<StampDataModel> updatedStamps = state.stamps
        .where((StampDataModel stamp) => stamp.id != id)
        .toList(growable: false);
    await _repository.saveCache(updatedStamps);
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(updatedStamps);

    emit(
      state.copyWith(
        isDeleting: false,
        showDeleteConfirm: false,
        selectedStampId: null,
        stamps: updatedStamps,
        collections: collections,
        view: StampverseView.home,
        homeTab: StampverseHomeTab.collection,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.clearSession();
    emit(
      state.copyWith(
        authToken: null,
        user: null,
        stamps: <StampDataModel>[],
        collections: <String>[],
        editBoards: <StampEditBoard>[],
        activeEditBoardId: null,
        selectedStampId: null,
        activeCollection: null,
        currentCapture: null,
        currentCaptureShape: StampShapeType.scallop,
        cameraDraftImage: null,
        cameraShape: StampShapeType.scallop,
        isLiveCameraActive: false,
        view: StampverseView.home,
        homeTab: StampverseHomeTab.stamp,
        showDeleteConfirm: false,
        errorMessage: null,
      ),
    );
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
