import 'package:equatable/equatable.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';

enum StampverseView {
  login,
  register,
  home,
  camera,
  save,
  album,
  details,
  editCreate,
  editBoard,
}

enum StampverseHomeTab { stamp, collection, memory, edit, settings }

class StampverseState extends Equatable {
  const StampverseState({
    required this.view,
    required this.homeTab,
    required this.lastMainHomeTab,
    required this.stamps,
    required this.collections,
    required this.editBoards,
    this.selectedEditBoardIds = const <String>[],
    this.authToken,
    this.user,
    this.currentCapture,
    this.currentCaptureShape = StampShapeType.scallop,
    this.cameraDraftImage,
    this.cameraShape = StampShapeType.scallop,
    this.activeCollection,
    this.activeEditBoardId,
    this.isLiveCameraActive = false,
    this.selectedStampId,
    this.errorMessage,
    this.isSubmittingLogin = false,
    this.isSubmittingRegister = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.isSyncing = false,
    this.showDeleteConfirm = false,
    this.registerSuccess = false,
    this.isInitialized = false,
  }) : assert(lastMainHomeTab != StampverseHomeTab.settings);

  factory StampverseState.initial() {
    return const StampverseState(
      view: StampverseView.home,
      homeTab: StampverseHomeTab.stamp,
      lastMainHomeTab: StampverseHomeTab.stamp,
      stamps: <StampDataModel>[],
      collections: <String>[],
      editBoards: <StampEditBoard>[],
    );
  }

  final StampverseView view;
  final StampverseHomeTab homeTab;
  final StampverseHomeTab lastMainHomeTab;
  final List<StampDataModel> stamps;
  final List<String> collections;
  final List<StampEditBoard> editBoards;
  final List<String> selectedEditBoardIds;
  final String? authToken;
  final Map<String, dynamic>? user;
  final String? currentCapture;
  final StampShapeType currentCaptureShape;
  final String? cameraDraftImage;
  final StampShapeType cameraShape;
  final String? activeCollection;
  final String? activeEditBoardId;
  final bool isLiveCameraActive;
  final String? selectedStampId;
  final String? errorMessage;
  final bool isSubmittingLogin;
  final bool isSubmittingRegister;
  final bool isSaving;
  final bool isDeleting;
  final bool isSyncing;
  final bool showDeleteConfirm;
  final bool registerSuccess;
  final bool isInitialized;

  bool get isLoggedIn {
    final String? token = authToken;
    return token != null && token.isNotEmpty;
  }

  bool get isSelectingEditBoards => selectedEditBoardIds.isNotEmpty;

  StampverseState copyWith({
    StampverseView? view,
    StampverseHomeTab? homeTab,
    StampverseHomeTab? lastMainHomeTab,
    List<StampDataModel>? stamps,
    List<String>? collections,
    List<StampEditBoard>? editBoards,
    List<String>? selectedEditBoardIds,
    Object? authToken = _sentinel,
    Object? user = _sentinel,
    Object? currentCapture = _sentinel,
    StampShapeType? currentCaptureShape,
    Object? cameraDraftImage = _sentinel,
    StampShapeType? cameraShape,
    Object? activeCollection = _sentinel,
    Object? activeEditBoardId = _sentinel,
    bool? isLiveCameraActive,
    Object? selectedStampId = _sentinel,
    Object? errorMessage = _sentinel,
    bool? isSubmittingLogin,
    bool? isSubmittingRegister,
    bool? isSaving,
    bool? isDeleting,
    bool? isSyncing,
    bool? showDeleteConfirm,
    bool? registerSuccess,
    bool? isInitialized,
  }) {
    return StampverseState(
      view: view ?? this.view,
      homeTab: homeTab ?? this.homeTab,
      lastMainHomeTab: lastMainHomeTab ?? this.lastMainHomeTab,
      stamps: stamps ?? this.stamps,
      collections: collections ?? this.collections,
      editBoards: editBoards ?? this.editBoards,
      selectedEditBoardIds: selectedEditBoardIds ?? this.selectedEditBoardIds,
      authToken: authToken == _sentinel ? this.authToken : authToken as String?,
      user: user == _sentinel ? this.user : user as Map<String, dynamic>?,
      currentCapture: currentCapture == _sentinel
          ? this.currentCapture
          : currentCapture as String?,
      currentCaptureShape: currentCaptureShape ?? this.currentCaptureShape,
      cameraDraftImage: cameraDraftImage == _sentinel
          ? this.cameraDraftImage
          : cameraDraftImage as String?,
      cameraShape: cameraShape ?? this.cameraShape,
      activeCollection: activeCollection == _sentinel
          ? this.activeCollection
          : activeCollection as String?,
      activeEditBoardId: activeEditBoardId == _sentinel
          ? this.activeEditBoardId
          : activeEditBoardId as String?,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      selectedStampId: selectedStampId == _sentinel
          ? this.selectedStampId
          : selectedStampId as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isSubmittingLogin: isSubmittingLogin ?? this.isSubmittingLogin,
      isSubmittingRegister: isSubmittingRegister ?? this.isSubmittingRegister,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isSyncing: isSyncing ?? this.isSyncing,
      showDeleteConfirm: showDeleteConfirm ?? this.showDeleteConfirm,
      registerSuccess: registerSuccess ?? this.registerSuccess,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    view,
    homeTab,
    lastMainHomeTab,
    stamps,
    collections,
    editBoards,
    selectedEditBoardIds,
    authToken,
    user,
    currentCapture,
    currentCaptureShape,
    cameraDraftImage,
    cameraShape,
    activeCollection,
    activeEditBoardId,
    isLiveCameraActive,
    selectedStampId,
    errorMessage,
    isSubmittingLogin,
    isSubmittingRegister,
    isSaving,
    isDeleting,
    isSyncing,
    showDeleteConfirm,
    registerSuccess,
    isInitialized,
  ];
}

const Object _sentinel = Object();
