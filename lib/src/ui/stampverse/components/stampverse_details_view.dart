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
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_primary_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseDetailsView extends StatefulWidget {
  const StampverseDetailsView({
    super.key,
    required this.stamp,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onDeleteConfirmVisible,
    required this.showDeleteConfirm,
    this.isDeleting = false,
  });

  final StampDataModel stamp;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final ValueChanged<bool> onDeleteConfirmVisible;
  final bool showDeleteConfirm;
  final bool isDeleting;

  @override
  State<StampverseDetailsView> createState() => _StampverseDetailsViewState();
}

class _StampverseDetailsViewState extends State<StampverseDetailsView> {
  static const Duration _gallerySaveTimeout = Duration(seconds: 20);

  bool _isDownloading = false;
  bool _isSharing = false;

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
          isReturnPathOfIOS: true,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'saveFile timed out: $error',
        name: 'StampverseDetails',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
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
          isReturnImagePathOfIOS: true,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'saveImage timed out: $error',
        name: 'StampverseDetails',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }

    return _isSavedSuccessfully(imageResult);
  }

  void _showActionMessage(String message) {
    if (!mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    Get.rawSnackbar(
      message: message,
      backgroundColor: AppColors.black.withValues(alpha: 0.88),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
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
        _showActionMessage(LocaleKey.stampverseDetailsDownloadFailed.tr);
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
      );
    } catch (error, stackTrace) {
      developer.log(
        'Download stamp failed: $error',
        name: 'StampverseDetails',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      _showActionMessage(LocaleKey.stampverseDetailsDownloadFailed.tr);
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
        _showActionMessage(LocaleKey.stampverseDetailsShareFailed.tr);
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
      _showActionMessage(LocaleKey.stampverseDetailsShareFailed.tr);
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        StampverseStamp(
                          imageUrl: widget.stamp.imageUrl,
                          shapeType: widget.stamp.shapeType,
                          width: 256,
                        ),
                        const SizedBox(height: 48),
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
                        const SizedBox(height: 24),
                        Row(
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
                      ],
                    ),
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
