import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/locale/translation_manager.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_album_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_camera_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_details_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_edit_board_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_edit_create_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_home_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_login_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_register_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_save_view.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse/interactor/stampverse_bloc.dart';
import 'package:stamp_camera/src/ui/stampverse/interactor/stampverse_state.dart';
import 'package:stamp_camera/src/ui/widgets/app_inapp_webview.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampversePage extends StatefulWidget {
  const StampversePage({super.key});

  @override
  State<StampversePage> createState() => _StampversePageState();
}

class _StampversePageState extends State<StampversePage> {
  // TODO(legal-links): Fill these URLs when legal pages are ready.
  static const Map<String, String> _privacyPolicyUrlsByLanguage =
      <String, String>{'vi': '', 'en': ''};
  static const Map<String, String> _termsOfUseUrlsByLanguage = <String, String>{
    'vi': '',
    'en': '',
  };

  late final StampverseBloc _bloc;

  late final TextEditingController _loginUsernameController;
  late final TextEditingController _loginPasswordController;
  late final TextEditingController _registerUsernameController;
  late final TextEditingController _registerPhoneController;
  late final TextEditingController _registerPasswordController;
  late final TextEditingController _registerConfirmController;
  late final TextEditingController _saveNameController;
  late final TextEditingController _saveCollectionController;
  late final TextEditingController _editBoardNameController;

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<StampverseBloc>();

    _loginUsernameController = TextEditingController();
    _loginPasswordController = TextEditingController();
    _registerUsernameController = TextEditingController();
    _registerPhoneController = TextEditingController();
    _registerPasswordController = TextEditingController();
    _registerConfirmController = TextEditingController();
    _saveNameController = TextEditingController();
    _saveCollectionController = TextEditingController();
    _editBoardNameController = TextEditingController();

    _bloc.initialize();
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    _saveNameController.dispose();
    _saveCollectionController.dispose();
    _editBoardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StampverseBloc>.value(
      value: _bloc,
      child: BlocConsumer<StampverseBloc, StampverseState>(
        listener: (_, StampverseState state) {
          if (state.view == StampverseView.login) {
            _registerPasswordController.clear();
            _registerConfirmController.clear();
          }
          if (state.view == StampverseView.home) {
            _saveNameController.clear();
            _saveCollectionController.clear();
          }
          if (state.view != StampverseView.editCreate) {
            _editBoardNameController.clear();
          }
        },
        builder: (_, StampverseState state) {
          final Widget content = _buildCurrentView(state);
          final String? errorText = _resolveError(state.errorMessage);
          final bool showTopError =
              _shouldShowGlobalError(state.view) &&
              errorText != null &&
              errorText.isNotEmpty;
          final bool canSystemPop =
              state.view == StampverseView.home &&
              state.homeTab != StampverseHomeTab.settings;

          return PopScope(
            canPop: canSystemPop,
            onPopInvokedWithResult: (bool didPop, Object? _) {
              if (didPop || canSystemPop) return;
              _bloc.back();
            },
            child: Scaffold(
              backgroundColor: AppColors.stampverseBackground,
              body: Stack(
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<StampverseView>(state.view),
                      child: content,
                    ),
                  ),
                  if (showTopError)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      child: _ErrorBanner(
                        message: errorText,
                        onClose: _bloc.clearError,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentView(StampverseState state) {
    final String? errorText = _resolveError(state.errorMessage);

    switch (state.view) {
      case StampverseView.login:
        return StampverseLoginView(
          usernameController: _loginUsernameController,
          passwordController: _loginPasswordController,
          isLoading: state.isSubmittingLogin,
          errorText: errorText,
          onBack: () {},
          onSwitchToRegister: _bloc.openRegister,
          onSubmit: () {
            _bloc.login(
              username: _loginUsernameController.text,
              password: _loginPasswordController.text,
            );
          },
        );
      case StampverseView.register:
        return StampverseRegisterView(
          usernameController: _registerUsernameController,
          phoneController: _registerPhoneController,
          passwordController: _registerPasswordController,
          confirmController: _registerConfirmController,
          isLoading: state.isSubmittingRegister,
          isSuccess: state.registerSuccess,
          errorText: errorText,
          onBack: _bloc.back,
          onSwitchToLogin: _bloc.openLogin,
          onSubmit: () {
            _bloc.register(
              username: _registerUsernameController.text,
              phone: _registerPhoneController.text,
              password: _registerPasswordController.text,
              confirmPassword: _registerConfirmController.text,
            );
          },
        );
      case StampverseView.home:
        return StampverseHomeView(
          stamps: state.stamps,
          tab: state.homeTab,
          lastMainHomeTab: state.lastMainHomeTab,
          collections: _groupCollectionSummaries(state.stamps),
          editBoards: state.editBoards,
          selectedEditBoardIds: state.selectedEditBoardIds,
          onTabChanged: _bloc.changeHomeTab,
          onOpenCollection: _bloc.openCollectionAlbum,
          onOpenCreateEditBoard: _bloc.openEditBoardCreate,
          onOpenEditBoard: _bloc.openEditBoard,
          onStartEditBoardSelection: _bloc.startEditBoardSelection,
          onToggleEditBoardSelection: _bloc.toggleEditBoardSelection,
          onClearEditBoardSelection: _bloc.clearEditBoardSelection,
          onDeleteSelectedEditBoards: () {
            _bloc.deleteSelectedEditBoards();
          },
          onAddFromCamera: _bloc.openCamera,
          onAddFromFile: _pickImageFromGallery,
          onRefresh: _bloc.syncStamps,
          isRefreshing: state.isSyncing,
          onLogout: _bloc.logout,
          onOpenPrivacyPolicy: _openPrivacyPolicy,
          onOpenTermsOfUse: _openTermsOfUse,
          onSelectStamp: _bloc.selectStamp,
        );
      case StampverseView.editCreate:
        return StampverseEditCreateView(
          nameController: _editBoardNameController,
          onBack: _bloc.back,
          onSave: () {
            _bloc.createEditBoardFromName(_editBoardNameController.text);
          },
        );
      case StampverseView.editBoard:
        final StampEditBoard? board = _findActiveEditBoard(state);
        if (board == null) {
          return StampverseHomeView(
            stamps: state.stamps,
            tab: StampverseHomeTab.edit,
            lastMainHomeTab: state.lastMainHomeTab,
            collections: _groupCollectionSummaries(state.stamps),
            editBoards: state.editBoards,
            selectedEditBoardIds: state.selectedEditBoardIds,
            onTabChanged: _bloc.changeHomeTab,
            onOpenCollection: _bloc.openCollectionAlbum,
            onOpenCreateEditBoard: _bloc.openEditBoardCreate,
            onOpenEditBoard: _bloc.openEditBoard,
            onStartEditBoardSelection: _bloc.startEditBoardSelection,
            onToggleEditBoardSelection: _bloc.toggleEditBoardSelection,
            onClearEditBoardSelection: _bloc.clearEditBoardSelection,
            onDeleteSelectedEditBoards: () {
              _bloc.deleteSelectedEditBoards();
            },
            onAddFromCamera: _bloc.openCamera,
            onAddFromFile: _pickImageFromGallery,
            onRefresh: _bloc.syncStamps,
            isRefreshing: state.isSyncing,
            onLogout: _bloc.logout,
            onOpenPrivacyPolicy: _openPrivacyPolicy,
            onOpenTermsOfUse: _openTermsOfUse,
            onSelectStamp: _bloc.selectStamp,
          );
        }
        return StampverseEditBoardView(
          board: board,
          allBoards: state.editBoards,
          stamps: state.stamps,
          onBack: _bloc.back,
          onSaveBoard: _bloc.saveEditBoard,
        );
      case StampverseView.camera:
        return StampverseCameraView(
          draftImage: state.cameraDraftImage,
          selectedShape: state.cameraShape,
          onShapeChanged: _bloc.updateCameraShape,
          onBack: _bloc.back,
          onCaptureLiveCamera: _bloc.captureLiveAndOpenSave,
          onReset: _bloc.resetCameraDraft,
          onConfirmCrop: _bloc.confirmCrop,
        );
      case StampverseView.save:
        final String image = state.currentCapture ?? '';

        return StampverseSaveView(
          imageUrl: image,
          shapeType: state.currentCaptureShape,
          nameController: _saveNameController,
          collectionController: _saveCollectionController,
          collections: state.collections,
          defaultCollection: '',
          onBack: _bloc.back,
          onSave: () {
            final String rawName = _saveNameController.text.trim().isEmpty
                ? LocaleKey.stampverseSaveDefaultName.tr
                : _saveNameController.text.trim();
            final String rawCollection = _saveCollectionController.text.trim();

            _bloc.saveStamp(rawName: rawName, rawCollection: rawCollection);
          },
        );
      case StampverseView.album:
        final List<StampDataModel> albumStamps = _resolveAlbumStamps(state);
        return StampverseAlbumView(
          stamps: albumStamps,
          title: state.activeCollection?.trim().isNotEmpty == true
              ? state.activeCollection!
              : LocaleKey.stampverseAlbumTitle.tr,
          onBack: _bloc.back,
          onSelectStamp: _bloc.selectStamp,
        );
      case StampverseView.details:
        final StampDataModel? selected = _findSelected(state);
        if (selected == null) {
          final List<StampDataModel> albumStamps = _resolveAlbumStamps(state);
          return StampverseAlbumView(
            stamps: albumStamps,
            title: state.activeCollection?.trim().isNotEmpty == true
                ? state.activeCollection!
                : LocaleKey.stampverseAlbumTitle.tr,
            onBack: _bloc.back,
            onSelectStamp: _bloc.selectStamp,
          );
        }
        return StampverseDetailsView(
          stamp: selected,
          showDeleteConfirm: state.showDeleteConfirm,
          isDeleting: state.isDeleting,
          onBack: _bloc.back,
          onToggleFavorite: () => _bloc.toggleFavoriteStamp(selected.id),
          onDelete: _bloc.deleteSelectedStamp,
          onDeleteConfirmVisible: _bloc.showDeleteConfirm,
        );
    }
  }

  StampDataModel? _findSelected(StampverseState state) {
    final String? selectedId = state.selectedStampId;
    if (selectedId == null) return null;

    for (final StampDataModel item in state.stamps) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  StampEditBoard? _findActiveEditBoard(StampverseState state) {
    final String? activeId = state.activeEditBoardId;
    if (activeId == null || activeId.isEmpty) return null;

    for (final StampEditBoard board in state.editBoards) {
      if (board.id == activeId) return board;
    }
    return null;
  }

  List<StampDataModel> _resolveAlbumStamps(StampverseState state) {
    final String? collection = state.activeCollection;
    if (collection == null || collection.isEmpty) {
      return state.stamps;
    }

    return state.stamps
        .where((StampDataModel item) {
          return (item.album?.trim() ?? '') == collection;
        })
        .toList(growable: false);
  }

  List<StampverseCollectionSummary> _groupCollectionSummaries(
    List<StampDataModel> stamps,
  ) {
    final Map<String, List<StampDataModel>> grouped =
        <String, List<StampDataModel>>{};

    for (final StampDataModel item in stamps) {
      final String key = item.album?.trim() ?? '';
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <StampDataModel>[]).add(item);
    }

    final List<StampverseCollectionSummary> result = grouped.entries
        .map(
          (MapEntry<String, List<StampDataModel>> entry) =>
              StampverseCollectionSummary(name: entry.key, stamps: entry.value),
        )
        .toList(growable: false);

    result.sort(
      (StampverseCollectionSummary a, StampverseCollectionSummary b) =>
          b.latestDate.compareTo(a.latestDate),
    );
    return result;
  }

  String? _resolveError(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    if (raw == 'PASSWORD_MISMATCH') {
      return LocaleKey.stampverseRegisterPasswordMismatch.tr;
    }
    if (raw == 'CAMERA_PERMISSION_ERROR') {
      return LocaleKey.stampverseCameraPermissionError.tr;
    }

    return raw;
  }

  bool _shouldShowGlobalError(StampverseView view) {
    return view == StampverseView.home ||
        view == StampverseView.camera ||
        view == StampverseView.album ||
        view == StampverseView.details ||
        view == StampverseView.save ||
        view == StampverseView.editCreate ||
        view == StampverseView.editBoard;
  }

  void _pickImageFromGallery() {
    _bloc.pickImage(ImageSource.gallery);
  }

  void _openPrivacyPolicy() {
    _openLegalDocument(
      title: LocaleKey.stampverseHomeSettingsPrivacyPolicy.tr,
      urlsByLanguage: _privacyPolicyUrlsByLanguage,
    );
  }

  void _openTermsOfUse() {
    _openLegalDocument(
      title: LocaleKey.stampverseHomeSettingsTermsOfUse.tr,
      urlsByLanguage: _termsOfUseUrlsByLanguage,
    );
  }

  void _openLegalDocument({
    required String title,
    required Map<String, String> urlsByLanguage,
  }) {
    final String url = _resolveLegalUrl(urlsByLanguage);
    if (url.isEmpty) {
      Get.rawSnackbar(
        messageText: Text(
          LocaleKey.stampverseHomeSettingsLegalLinkPending.tr,
          style: StampverseTextStyles.caption(color: AppColors.white),
        ),
        backgroundColor: AppColors.stampverseHeadingText,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    Get.to<void>(() => _StampverseLegalWebViewPage(title: title, url: url));
  }

  String _resolveLegalUrl(Map<String, String> urlsByLanguage) {
    final String languageCode =
        Get.locale?.languageCode ??
        TranslationManager.defaultLocale.languageCode;
    return (urlsByLanguage[languageCode] ??
            urlsByLanguage[TranslationManager.fallbackLocale.languageCode] ??
            '')
        .trim();
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.stampverseDangerSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.stampverseDanger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.stampverseDanger,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: StampverseTextStyles.caption(
                  color: AppColors.stampverseDanger,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.stampverseDanger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampverseLegalWebViewPage extends StatelessWidget {
  const _StampverseLegalWebViewPage({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stampverseBackground,
      appBar: AppBar(
        backgroundColor: AppColors.stampverseBackground,
        foregroundColor: AppColors.stampverseHeadingText,
        elevation: 0,
        title: Text(
          title,
          style: StampverseTextStyles.body(
            color: AppColors.stampverseHeadingText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(child: AppInAppWebView(url: url)),
    );
  }
}
