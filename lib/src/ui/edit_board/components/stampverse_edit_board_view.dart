import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/edit_board/components/stampverse_edit_background_painter.dart';
import 'package:stamp_camera/src/ui/edit_board/components/stampverse_edit_studio_view.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

enum _EditExportAction { download, share }

class StampverseEditBoardView extends StatefulWidget {
  const StampverseEditBoardView({
    super.key,
    required this.board,
    required this.allBoards,
    required this.stamps,
    required this.onBack,
    required this.onSaveBoard,
  });

  final StampEditBoard board;
  final List<StampEditBoard> allBoards;
  final List<StampDataModel> stamps;
  final VoidCallback onBack;
  final ValueChanged<StampEditBoard> onSaveBoard;

  @override
  State<StampverseEditBoardView> createState() =>
      _StampverseEditBoardViewState();
}

class _StampverseEditBoardViewState extends State<StampverseEditBoardView> {
  static const Duration _gallerySaveTimeout = Duration(seconds: 20);

  final StampverseEditStudioController _studioController =
      StampverseEditStudioController();

  bool _isDownloading = false;
  bool _isSharing = false;

  Future<void> _openRenameSheet() async {
    final String? nextName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _RenameBoardDialog(initialName: widget.board.name),
    );

    if (!mounted) return;

    if (nextName == null || nextName.isEmpty || nextName == widget.board.name) {
      return;
    }

    widget.onSaveBoard(widget.board.copyWith(name: nextName));
  }

  Future<void> _openImportSheet() async {
    await _studioController.openImportSheet();
  }

  String _backgroundLabel(StampEditBoardBackgroundStyle style) {
    switch (style) {
      case StampEditBoardBackgroundStyle.grid:
        return LocaleKey.stampverseHomeEditBackgroundGrid.tr;
      case StampEditBoardBackgroundStyle.dots:
        return LocaleKey.stampverseHomeEditBackgroundDots.tr;
      case StampEditBoardBackgroundStyle.paper:
        return LocaleKey.stampverseHomeEditBackgroundPaper.tr;
    }
  }

  Future<void> _openBackgroundMenu() async {
    final StampEditBoardBackgroundStyle? selected =
        await showModalBottomSheet<StampEditBoardBackgroundStyle>(
          context: context,
          backgroundColor: AppColors.stampverseSurface,
          showDragHandle: true,
          builder: (BuildContext context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        LocaleKey.stampverseHomeEditBackgroundLabel.tr,
                        style: StampverseTextStyles.body(
                          color: AppColors.stampverseHeadingText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...StampEditBoardBackgroundStyle.values.map((
                      StampEditBoardBackgroundStyle style,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BoardBackgroundOptionTile(
                          title: _backgroundLabel(style),
                          style: style,
                          selected: widget.board.backgroundStyle == style,
                          onTap: () => Navigator.of(context).pop(style),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );

    if (selected == null || selected == widget.board.backgroundStyle) return;
    widget.onSaveBoard(widget.board.copyWith(backgroundStyle: selected));
  }

  void _showActionMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final Color messageColor = isError
        ? AppColors.stampverseDanger
        : AppColors.stampverseSuccess;
    final Color backgroundColor = isError
        ? AppColors.stampverseDangerSoft
        : AppColors.stampverseSuccessSoft;
    final IconData iconData = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_rounded;
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: StampverseTextStyles.caption(
          color: messageColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: Icon(iconData, color: messageColor),
      backgroundColor: backgroundColor,
      borderColor: messageColor.withValues(alpha: 0.35),
      borderWidth: 1,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      dismissDirection: DismissDirection.horizontal,
    );
  }

  bool _isSavedSuccessfully(dynamic result) {
    if (result is Map) {
      final dynamic rawSuccess = result['isSuccess'] ?? result['success'];
      if (rawSuccess is bool) return rawSuccess;
      final dynamic rawPath = result['filePath'] ?? result['file_path'];
      if (rawPath != null && rawPath.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<dynamic> _awaitGalleryResult(FutureOr<dynamic> operation) async {
    if (operation is Future<dynamic>) {
      return operation.timeout(_gallerySaveTimeout);
    }
    return operation;
  }

  Future<bool> _saveImageToGallery({
    required Uint8List bytes,
    required File imageFile,
    required String fileName,
  }) async {
    dynamic fileResult;
    try {
      fileResult = await _awaitGalleryResult(
        ImageGallerySaverPlus.saveFile(
          imageFile.path,
          name: fileName,
          // Keep iOS path-return disabled to avoid plugin callbacks hanging.
          isReturnPathOfIOS: false,
        ),
      );
    } on TimeoutException {
      // Ignore and continue fallback save strategy.
    }

    if (_isSavedSuccessfully(fileResult)) {
      return true;
    }

    dynamic imageResult;
    try {
      imageResult = await _awaitGalleryResult(
        ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: fileName,
          // Keep iOS path-return disabled to avoid plugin callbacks hanging.
          isReturnImagePathOfIOS: false,
        ),
      );
    } on TimeoutException {
      // Ignore and continue fallback save strategy.
    }

    return _isSavedSuccessfully(imageResult);
  }

  Future<void> _downloadBoardImage(Uint8List bytes) async {
    final String fileName =
        'stamp_board_${widget.board.id}_${DateTime.now().millisecondsSinceEpoch}';
    final Directory tempDir = await getTemporaryDirectory();
    final String savePath = '${tempDir.path}/$fileName.png';
    final File imageFile = File(savePath);
    await imageFile.writeAsBytes(bytes, flush: true);

    final bool isSuccess = await _saveImageToGallery(
      bytes: bytes,
      imageFile: imageFile,
      fileName: fileName,
    );

    _showActionMessage(
      isSuccess
          ? LocaleKey.stampverseDetailsDownloadSuccess.tr
          : LocaleKey.stampverseDetailsDownloadFailed.tr,
      isError: !isSuccess,
    );
  }

  Future<void> _shareBoardImage(Uint8List bytes) async {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Rect? shareOrigin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/stamp_board_share_${widget.board.id}_${DateTime.now().millisecondsSinceEpoch}.png';

    final File imageFile = File(filePath);
    await imageFile.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(imageFile.path)],
        text: widget.board.name,
        subject: widget.board.name,
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  Future<void> _exportBoard({required bool share}) async {
    if (share && _isSharing) return;
    if (!share && _isDownloading) return;

    setState(() {
      if (share) {
        _isSharing = true;
      } else {
        _isDownloading = true;
      }
    });

    try {
      final Uint8List? bytes = await _studioController.captureBoardImage();
      if (bytes == null || bytes.isEmpty) {
        _showActionMessage(
          share
              ? LocaleKey.stampverseDetailsShareFailed.tr
              : LocaleKey.stampverseDetailsDownloadFailed.tr,
          isError: true,
        );
        return;
      }

      if (share) {
        await _shareBoardImage(bytes);
      } else {
        await _downloadBoardImage(bytes);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Export board failed: $error',
        name: 'StampverseEditBoard',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      _showActionMessage(
        share
            ? LocaleKey.stampverseDetailsShareFailed.tr
            : LocaleKey.stampverseDetailsDownloadFailed.tr,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (share) {
            _isSharing = false;
          } else {
            _isDownloading = false;
          }
        });
      }
    }
  }

  Future<void> _openShareMenu() async {
    final _EditExportAction? action =
        await showModalBottomSheet<_EditExportAction>(
          context: context,
          backgroundColor: AppColors.stampverseSurface,
          showDragHandle: true,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.download_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                    title: Text(LocaleKey.stampverseDetailsDownload.tr),
                    onTap: () =>
                        Navigator.of(context).pop(_EditExportAction.download),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                    title: Text(LocaleKey.stampverseDetailsShare.tr),
                    onTap: () =>
                        Navigator.of(context).pop(_EditExportAction.share),
                  ),
                ],
              ),
            );
          },
        );

    if (action == null) return;
    if (action == _EditExportAction.download) {
      await _exportBoard(share: false);
      return;
    }
    await _exportBoard(share: true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemplateBoard =
        widget.board.editorMode == StampEditBoardEditorMode.template;

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openRenameSheet,
                      child: Text(
                        widget.board.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StampverseTextStyles.sectionTitle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isDownloading || _isSharing
                        ? null
                        : _openShareMenu,
                    icon: _isDownloading || _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.ios_share_rounded,
                            color: AppColors.stampversePrimaryText,
                          ),
                    tooltip: LocaleKey.stampverseDetailsShare.tr,
                  ),
                  const SizedBox(width: 2),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.colorF586AA6.withValues(alpha: 0.2),
                          AppColors.colorF586AA6.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.colorF586AA6.withValues(alpha: 0.4),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _openBackgroundMenu,
                      icon: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: AppColors.colorF586AA6,
                      ),
                      tooltip: LocaleKey.stampverseHomeEditBackgroundLabel.tr,
                    ),
                  ),
                  const SizedBox(width: 2),
                  if (!isTemplateBoard)
                    IconButton(
                      onPressed: _openImportSheet,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.stampversePrimaryText,
                      ),
                      tooltip: LocaleKey.stampverseHomeEditImportStamp.tr,
                    ),
                ],
              ),
            ),
            Expanded(
              child: StampverseEditStudioView(
                boards: widget.allBoards,
                activeBoardId: widget.board.id,
                stamps: widget.stamps,
                onSaveBoard: widget.onSaveBoard,
                controller: _studioController,
                showBoardHeader: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardBackgroundOptionTile extends StatelessWidget {
  const _BoardBackgroundOptionTile({
    required this.title,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final StampEditBoardBackgroundStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 88,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? AppColors.colorF586AA6.withValues(alpha: 0.12)
                : AppColors.white,
            border: Border.all(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampverseBorderSoft,
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 68,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(
                        color: AppColors.stampverseBorderSoft.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    child: CustomPaint(
                      painter: StampverseEditBackgroundPainter(
                        backgroundStyle: style,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: StampverseTextStyles.body(
                    color: AppColors.stampverseHeadingText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.colorF586AA6
                    : AppColors.stampverseMutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameBoardDialog extends StatefulWidget {
  const _RenameBoardDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameBoardDialog> createState() => _RenameBoardDialogState();
}

class _RenameBoardDialogState extends State<_RenameBoardDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.stampverseSurface,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.colorF586AA6.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: AppColors.colorF586AA6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              LocaleKey.stampverseEditBoardRenameTitle.tr,
              style: StampverseTextStyles.body(
                color: AppColors.stampverseHeadingText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        style: StampverseTextStyles.input(),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: LocaleKey.stampverseEditCreateNamePlaceholder.tr,
          hintStyle: StampverseTextStyles.body(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKey.cancel.tr),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(LocaleKey.stampverseEditBoardRenameSave.tr),
        ),
      ],
    );
  }
}
