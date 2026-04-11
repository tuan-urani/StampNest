import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_primary_button.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseDetailsView extends StatefulWidget {
  const StampverseDetailsView({
    super.key,
    required this.stamp,
    required this.collections,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onAssignCollection,
    required this.onDelete,
    required this.onDeleteConfirmVisible,
    required this.showDeleteConfirm,
    this.canSwipePrevious = false,
    this.canSwipeNext = false,
    this.onSwipePrevious,
    this.onSwipeNext,
    this.isDeleting = false,
    this.isAssigningCollection = false,
  });

  final StampDataModel stamp;
  final List<String> collections;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final Future<bool> Function(String collectionName) onAssignCollection;
  final VoidCallback onDelete;
  final ValueChanged<bool> onDeleteConfirmVisible;
  final bool showDeleteConfirm;
  final bool canSwipePrevious;
  final bool canSwipeNext;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;
  final bool isDeleting;
  final bool isAssigningCollection;

  @override
  State<StampverseDetailsView> createState() => _StampverseDetailsViewState();
}

class _StampverseDetailsViewState extends State<StampverseDetailsView> {
  static const Duration _gallerySaveTimeout = Duration(seconds: 20);
  static const double _kSwipeDistanceThreshold = 28;
  static const double _kSwipeVelocityThreshold = 120;

  bool _isDownloading = false;
  bool _isSharing = false;
  double _horizontalDragDx = 0;

  void _onSwipeDragStart(DragStartDetails _) {
    _horizontalDragDx = 0;
  }

  void _onSwipeDragUpdate(DragUpdateDetails details) {
    _horizontalDragDx += details.delta.dx;
  }

  void _onSwipeDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldGoPrevious =
        (_horizontalDragDx > _kSwipeDistanceThreshold ||
            velocity > _kSwipeVelocityThreshold) &&
        widget.canSwipePrevious &&
        widget.onSwipePrevious != null;
    final bool shouldGoNext =
        (_horizontalDragDx < -_kSwipeDistanceThreshold ||
            velocity < -_kSwipeVelocityThreshold) &&
        widget.canSwipeNext &&
        widget.onSwipeNext != null;

    _horizontalDragDx = 0;

    if (shouldGoPrevious) {
      widget.onSwipePrevious!.call();
      return;
    }
    if (shouldGoNext) {
      widget.onSwipeNext!.call();
    }
  }

  Future<Uint8List?> _resolveImageBytes(String imageUrl) async {
    try {
      if (imageUrl.startsWith('data:image')) {
        final int comma = imageUrl.indexOf(',');
        if (comma < 0 || comma >= imageUrl.length - 1) return null;
        return base64Decode(imageUrl.substring(comma + 1));
      }

      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        final ByteData data = await NetworkAssetBundle(
          Uri.parse(imageUrl),
        ).load(imageUrl);
        return data.buffer.asUint8List();
      }

      final ByteData data = await rootBundle.load(imageUrl);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  String _resolveImageExtension(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final RegExpMatch? match = RegExp(
        r'^data:image/([^;]+);',
      ).firstMatch(imageUrl);
      final String ext = (match?.group(1) ?? 'png').toLowerCase();
      if (ext == 'jpeg') return 'jpg';
      return ext;
    }

    if (imageUrl.startsWith('http')) {
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.path.toLowerCase();
      if (path.endsWith('.png')) return 'png';
      if (path.endsWith('.webp')) return 'webp';
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpg';
    }

    if (imageUrl.toLowerCase().endsWith('.png')) return 'png';
    if (imageUrl.toLowerCase().endsWith('.webp')) return 'webp';
    if (imageUrl.toLowerCase().endsWith('.jpg') ||
        imageUrl.toLowerCase().endsWith('.jpeg')) {
      return 'jpg';
    }

    return 'png';
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

  Future<String?> _promptCreateCollectionName() async {
    final TextEditingController controller = TextEditingController();
    final String? rawValue = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.stampverseSurface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 26,
            vertical: 24,
          ),
          title: Text(
            LocaleKey.stampverseSaveCollectionCreateTitle.tr,
            style: StampverseTextStyles.heroTitle(
              color: AppColors.stampverseHeadingText,
            ),
          ),
          content: TextField(
            controller: controller,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
            style: StampverseTextStyles.body(
              color: AppColors.black,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: LocaleKey.stampverseSaveCollectionCreatePlaceholder.tr,
              hintStyle: StampverseTextStyles.body(
                color: AppColors.colorB7B7B7,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.stampverseBorderSoft,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.stampverseBorderSoft,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.colorF586AA6,
                  width: 1.2,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                LocaleKey.widgetCancel.tr,
                style: StampverseTextStyles.body(
                  color: AppColors.stampverseMutedText,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(
                LocaleKey.widgetConfirm.tr,
                style: StampverseTextStyles.body(
                  color: AppColors.colorF586AA6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final String normalized = rawValue?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    for (final String item in widget.collections) {
      if (item.trim().toLowerCase() == normalized.toLowerCase()) {
        return item.trim();
      }
    }
    return normalized;
  }

  Future<String?> _openCollectionPickerSheet() {
    final List<String> options =
        widget.collections
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(
            (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.stampverseSurface,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKey.stampverseDetailsCollectionSheetTitle.tr,
                  style: StampverseTextStyles.heroTitle(
                    color: AppColors.stampverseHeadingText,
                  ),
                ),
                const SizedBox(height: 10),
                if (options.isEmpty) ...<Widget>[
                  Text(
                    LocaleKey.stampverseDetailsCollectionEmpty.tr,
                    style: StampverseTextStyles.body(),
                  ),
                  const SizedBox(height: 14),
                  StampversePrimaryButton(
                    label: LocaleKey.stampverseSaveCollectionCreateAction.tr,
                    onTap: () async {
                      final String? created =
                          await _promptCreateCollectionName();
                      if (!sheetContext.mounted || created == null) return;
                      Navigator.of(sheetContext).pop(created);
                    },
                  ),
                ] else ...<Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, int index) {
                        final String item = options[index];
                        return Material(
                          color: AppColors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(sheetContext).pop(item),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.stampverseBorderSoft,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.collections_bookmark_outlined,
                                      size: 18,
                                      color: AppColors.colorF586AA6,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: StampverseTextStyles.body(
                                          color:
                                              AppColors.stampverseHeadingText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  StampversePrimaryButton(
                    label: LocaleKey.stampverseSaveCollectionCreateAction.tr,
                    onTap: () async {
                      final String? created =
                          await _promptCreateCollectionName();
                      if (!sheetContext.mounted || created == null) return;
                      Navigator.of(sheetContext).pop(created);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addStampToCollection() async {
    if (widget.isAssigningCollection) return;

    final String? selectedCollection = await _openCollectionPickerSheet();
    if (!mounted || selectedCollection == null || selectedCollection.isEmpty) {
      return;
    }

    final bool isSuccess = await widget.onAssignCollection(selectedCollection);
    if (!mounted) return;
    _showActionMessage(
      isSuccess
          ? LocaleKey.stampverseDetailsCollectionAssignSuccess.tr
          : LocaleKey.stampverseDetailsCollectionAssignFailed.tr,
      isError: !isSuccess,
    );
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final Uint8List? bytes = await _resolveImageBytes(widget.stamp.imageUrl);
      if (bytes == null || bytes.isEmpty) {
        _showActionMessage(
          LocaleKey.stampverseDetailsDownloadFailed.tr,
          isError: true,
        );
        return;
      }

      final String fileName =
          'stamp_${widget.stamp.id}_${DateTime.now().millisecondsSinceEpoch}';
      final Directory tempDir = await getTemporaryDirectory();
      final String ext = _resolveImageExtension(widget.stamp.imageUrl);
      final String savePath = '${tempDir.path}/$fileName.$ext';
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
    } catch (error, stackTrace) {
      developer.log(
        'Download stamp failed: $error',
        name: 'StampverseDetails',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      _showActionMessage(
        LocaleKey.stampverseDetailsDownloadFailed.tr,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    if (_isSharing) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Rect? shareOrigin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    setState(() {
      _isSharing = true;
    });

    try {
      final Uint8List? bytes = await _resolveImageBytes(widget.stamp.imageUrl);
      if (bytes == null || bytes.isEmpty) {
        _showActionMessage(
          LocaleKey.stampverseDetailsShareFailed.tr,
          isError: true,
        );
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String ext = _resolveImageExtension(widget.stamp.imageUrl);
      final String filePath =
          '${tempDir.path}/stamp_share_${widget.stamp.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(imageFile.path)],
          text: widget.stamp.name,
          subject: widget.stamp.name,
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Share stamp failed: $error',
        name: 'StampverseDetails',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      _showActionMessage(
        LocaleKey.stampverseDetailsShareFailed.tr,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = widget.stamp.parsedDate ?? DateTime.now();
    final String dateText = DateFormat('MMMM d, y', 'en_US').format(date);
    final bool hasCollection = (widget.stamp.album?.trim() ?? '').isNotEmpty;

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: <Widget>[
                      StampverseIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: widget.onBack,
                      ),
                      const Spacer(),
                      StampverseIconButton(
                        icon: widget.stamp.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: widget.stamp.isFavorite
                            ? AppColors.stampverseDanger
                            : AppColors.stampversePrimaryText,
                        onTap: () {
                          final bool isRemoving = widget.stamp.isFavorite;
                          widget.onToggleFavorite();
                          _showActionMessage(
                            isRemoving
                                ? LocaleKey.stampverseDetailsFavoriteRemoved.tr
                                : LocaleKey.stampverseDetailsFavoriteAdded.tr,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      StampverseIconButton(
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.stampverseDanger,
                        onTap: () => widget.onDeleteConfirmVisible(true),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: _onSwipeDragStart,
                    onHorizontalDragUpdate: _onSwipeDragUpdate,
                    onHorizontalDragEnd: _onSwipeDragEnd,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final bool isCompactHeight =
                                constraints.maxHeight < 560;
                            const double stampWidth = 200;
                            final Widget stampPreview = Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                StampverseStamp(
                                  imageUrl: widget.stamp.imageUrl,
                                  shapeType: widget.stamp.shapeType,
                                  applyShapeClip: false,
                                  width: stampWidth,
                                  showShadow: false,
                                ),
                                if (widget.canSwipePrevious)
                                  const Positioned(
                                    left: -4,
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 24,
                                      color: AppColors.stampverseMutedText,
                                    ),
                                  ),
                                if (widget.canSwipeNext)
                                  const Positioned(
                                    right: -4,
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 24,
                                      color: AppColors.stampverseMutedText,
                                    ),
                                  ),
                              ],
                            );

                            final Widget content = Column(
                              mainAxisAlignment: isCompactHeight
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: <Widget>[
                                if (isCompactHeight) const SizedBox(height: 8),
                                stampPreview,
                                const SizedBox(height: 40),
                                Text(
                                  widget.stamp.name,
                                  textAlign: TextAlign.center,
                                  style: StampverseTextStyles.heroTitle(
                                    color: AppColors.stampverseHeadingText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateText,
                                  style: StampverseTextStyles.body(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );

                            if (isCompactHeight) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  12,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight - 12,
                                  ),
                                  child: content,
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: content,
                            );
                          },
                    ),
                  ),
                ),
                if (!hasCollection)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: _DetailActionButton(
                      icon: Icons.collections_bookmark_outlined,
                      label: LocaleKey.stampverseDetailsAddToCollection.tr,
                      onTap: _addStampToCollection,
                      isLoading: widget.isAssigningCollection,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _DetailActionButton(
                          icon: Icons.download_rounded,
                          label: LocaleKey.stampverseDetailsDownload.tr,
                          onTap: _downloadImage,
                          isLoading: _isDownloading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailActionButton(
                          icon: Icons.ios_share_rounded,
                          label: LocaleKey.stampverseDetailsShare.tr,
                          onTap: _shareImage,
                          isLoading: _isSharing,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.showDeleteConfirm) ...<Widget>[
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.black.withValues(alpha: 0.2),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.stampverseDangerSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.stampverseDanger,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              LocaleKey.stampverseDetailsDeleteTitle.tr,
                              textAlign: TextAlign.center,
                              style: StampverseTextStyles.heroTitle(
                                color: AppColors.stampverseHeadingText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocaleKey.stampverseDetailsDeleteBody.tr,
                              textAlign: TextAlign.center,
                              style: StampverseTextStyles.caption(),
                            ),
                            const SizedBox(height: 16),
                            StampversePrimaryButton(
                              label: widget.isDeleting
                                  ? '${LocaleKey.stampverseDetailsDeleteConfirm.tr}...'
                                  : LocaleKey.stampverseDetailsDeleteConfirm.tr,
                              enabled: !widget.isDeleting,
                              onTap: widget.onDelete,
                            ),
                            const SizedBox(height: 10),
                            StampversePrimaryButton(
                              label: LocaleKey.stampverseDetailsDeleteCancel.tr,
                              enabled: !widget.isDeleting,
                              onTap: () => widget.onDeleteConfirmVisible(false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stampverseBorderSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 18, color: AppColors.stampversePrimaryText),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: StampverseTextStyles.body(
                    color: AppColors.stampversePrimaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
