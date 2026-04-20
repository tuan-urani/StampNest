import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_frame_shape.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/edit_board/components/stampverse_edit_background_painter.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_template_frame_path.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CreativeTabContent extends StatelessWidget {
  const CreativeTabContent({
    super.key,
    required this.boards,
    required this.selectedBoardIds,
    required this.onOpenTemplates,
    required this.onOpenBoard,
    required this.onStartSelection,
    required this.onToggleSelection,
  });

  final List<StampEditBoard> boards;
  final List<String> selectedBoardIds;
  final VoidCallback onOpenTemplates;
  final ValueChanged<String> onOpenBoard;
  final ValueChanged<String> onStartSelection;
  final ValueChanged<String> onToggleSelection;

  @override
  Widget build(BuildContext context) {
    if (boards.isEmpty) {
      return StampverseEmptyTab(
        icon: Icons.edit_note_rounded,
        title: LocaleKey.stampverseHomeEditEmptyTitle.tr,
        subtitle: '',
        actionLabel: LocaleKey.stampverseCreativeBrowseTemplates.tr,
        onActionTap: onOpenTemplates,
      );
    }

    final Set<String> selectedSet = selectedBoardIds.toSet();
    final bool isSelectionMode = selectedSet.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        StampverseLayout.contentBottomPadding,
      ),
      children: <Widget>[
        if (!isSelectionMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenTemplates,
              child: Text(
                LocaleKey.stampverseHomeEditCreateBoard.tr,
                style: StampverseTextStyles.caption(
                  color: AppColors.colorF586AA6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        SizedBox(height: isSelectionMode ? 0 : 6),
        ...boards.map((StampEditBoard board) {
          final bool isSelected = selectedSet.contains(board.id);
          final String updatedAtLabel = DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(board.parsedUpdatedAt.toLocal());

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: isSelected
                  ? AppColors.colorF586AA6.withValues(alpha: 0.15)
                  : AppColors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (isSelectionMode) {
                    onToggleSelection(board.id);
                    return;
                  }
                  onOpenBoard(board.id);
                },
                onLongPress: () {
                  if (isSelectionMode) {
                    onToggleSelection(board.id);
                    return;
                  }
                  onStartSelection(board.id);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.colorF586AA6
                          : AppColors.stampverseBorderSoft,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.stampverseShadowCard,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 78,
                          child: _CreativeBoardPreview(board: board, width: 78),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                board.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: StampverseTextStyles.body(
                                  color: AppColors.stampverseHeadingText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                LocaleKey.stampverseHomeStampsCount.trParams(
                                  <String, String>{
                                    'count': '${board.layers.length}',
                                  },
                                ),
                                style: StampverseTextStyles.caption(
                                  color: AppColors.stampverseMutedText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                updatedAtLabel,
                                style: StampverseTextStyles.caption(
                                  color: AppColors.stampverseMutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        isSelectionMode
                            ? Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.colorF586AA6
                                    : AppColors.stampverseMutedText,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.stampverseMutedText,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CreativeBoardPreview extends StatelessWidget {
  const _CreativeBoardPreview({required this.board, required this.width});

  static const double _kFreeformBaseWidthRatio = 116 / 320;
  static const double _kTemplateSlotMinRatio = 0.12;
  static const double _kTemplateSlotMaxRatio = 0.96;

  final StampEditBoard board;
  final double width;

  bool get _isTemplateBoard {
    return board.editorMode == StampEditBoardEditorMode.template;
  }

  Color _resolveCanvasColor() {
    if (!_isTemplateBoard) return AppColors.white;
    final String rawColor = board.templateCanvasColorHex?.trim() ?? '';
    if (rawColor.isEmpty) return AppColors.white;
    try {
      return AppColors.fromHex(rawColor);
    } catch (_) {
      return AppColors.white;
    }
  }

  double _resolvePreviewAspectRatio() {
    if (!_isTemplateBoard) return 1;
    final double? sourceWidth = board.templateSourceWidth;
    final double? sourceHeight = board.templateSourceHeight;
    if (sourceWidth == null || sourceHeight == null) return 1;
    if (sourceWidth <= 0 || sourceHeight <= 0) return 1;

    final double aspectRatio = sourceWidth / sourceHeight;
    if (!aspectRatio.isFinite || aspectRatio <= 0) return 1;
    return aspectRatio.clamp(0.56, 1.85).toDouble();
  }

  Widget _buildLayer({
    required StampEditLayer layer,
    required Size canvasSize,
  }) {
    if (_isTemplateBoard &&
        layer.layerType == StampEditLayerType.templateSlot) {
      return _buildTemplateLayer(layer: layer, canvasSize: canvasSize);
    }
    return _buildFreeformLayer(layer: layer, canvasSize: canvasSize);
  }

  Widget _buildFreeformLayer({
    required StampEditLayer layer,
    required Size canvasSize,
  }) {
    final double baseWidth = (canvasSize.width * _kFreeformBaseWidthRatio)
        .clamp(16, canvasSize.width * 0.92)
        .toDouble();
    final double safeScale = layer.scale.isFinite
        ? layer.scale.clamp(0.15, 6).toDouble()
        : 1;
    final double layerWidth = baseWidth * safeScale;
    final double layerHeight = layerWidth / layer.shapeType.aspectRatio;
    final double left = (layer.centerX * canvasSize.width) - (layerWidth / 2);
    final double top = (layer.centerY * canvasSize.height) - (layerHeight / 2);

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: layer.rotation.isFinite ? layer.rotation : 0,
        child: StampverseStamp(
          imageUrl: layer.imageUrl,
          shapeType: layer.shapeType,
          applyShapeClip: false,
          width: layerWidth,
          showShadow: false,
        ),
      ),
    );
  }

  Widget _buildTemplateLayer({
    required StampEditLayer layer,
    required Size canvasSize,
  }) {
    final double widthRatio = (layer.widthRatio ?? 0.32)
        .clamp(_kTemplateSlotMinRatio, _kTemplateSlotMaxRatio)
        .toDouble();
    final double heightRatio = (layer.heightRatio ?? 0.24)
        .clamp(_kTemplateSlotMinRatio, _kTemplateSlotMaxRatio)
        .toDouble();
    final double slotWidth = (canvasSize.width * widthRatio)
        .clamp(10, canvasSize.width)
        .toDouble();
    final double slotHeight = (canvasSize.height * heightRatio)
        .clamp(10, canvasSize.height)
        .toDouble();
    final double left = (layer.centerX * canvasSize.width) - (slotWidth / 2);
    final double top = (layer.centerY * canvasSize.height) - (slotHeight / 2);

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: slotWidth,
        height: slotHeight,
        child: Transform.rotate(
          angle: layer.rotation.isFinite ? layer.rotation : 0,
          child: _CreativeTemplateSlotPreview(layer: layer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (board.layers.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stampverseSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stampverseBorderSoft),
        ),
        child: const AspectRatio(
          aspectRatio: 1,
          child: Icon(
            Icons.photo_library_outlined,
            color: AppColors.stampverseMutedText,
          ),
        ),
      );
    }

    final double aspectRatio = _resolvePreviewAspectRatio();
    final String backgroundAssetPath =
        board.templateBackgroundAssetPath?.trim() ?? '';

    return SizedBox(
      width: width,
      height: width,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _resolveCanvasColor(),
                border: Border.all(
                  color: AppColors.stampverseBorderSoft.withValues(alpha: 0.82),
                ),
              ),
              child: LayoutBuilder(
                builder: (_, BoxConstraints constraints) {
                  final Size size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: <Widget>[
                      Positioned.fill(
                        child:
                            _isTemplateBoard &&
                                board.backgroundStyle ==
                                    StampEditBoardBackgroundStyle.grid
                            ? const SizedBox.shrink()
                            : CustomPaint(
                                painter: StampverseEditBackgroundPainter(
                                  backgroundStyle: board.backgroundStyle,
                                ),
                              ),
                      ),
                      if (_isTemplateBoard && backgroundAssetPath.isNotEmpty)
                        Positioned.fill(
                          child: Image.asset(
                            backgroundAssetPath,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ...board.layers.map(
                        (StampEditLayer layer) =>
                            _buildLayer(layer: layer, canvasSize: size),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreativeTemplateSlotPreview extends StatelessWidget {
  const _CreativeTemplateSlotPreview({required this.layer});

  final StampEditLayer layer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect rect = Offset.zero & size;
        final Path framePath = buildTemplateFramePath(
          frameShape: layer.frameShape,
          rect: rect,
        );

        final bool isClassicStamp =
            layer.frameShape == StampEditFrameShape.stampClassic;
        final bool hasImage = layer.imageUrl.trim().isNotEmpty;
        final Widget imageViewport = hasImage
            ? _CreativeTemplateSlotImageViewport(
                imageUrl: layer.imageUrl,
                scale: layer.contentScale,
                scaleX: layer.contentScaleX,
                scaleY: layer.contentScaleY,
                offsetX: layer.contentOffsetX,
                offsetY: layer.contentOffsetY,
                rotation: layer.contentRotation,
              )
            : const SizedBox.shrink();

        final Widget content = isClassicStamp
            ? _CreativeClassicSlotLayout(
                imageViewport: imageViewport,
                framePath: framePath,
                size: size,
              )
            : ClipPath(
                clipper: _CreativePathClipper(framePath),
                child: ColoredBox(
                  color: AppColors.stampverseBorderSoft.withValues(alpha: 0.4),
                  child: imageViewport,
                ),
              );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            content,
            CustomPaint(
              painter: _CreativeTemplateFrameBorderPainter(
                path: framePath,
                borderColor: isClassicStamp
                    ? AppColors.stampversePrimaryText
                    : AppColors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreativeClassicSlotLayout extends StatelessWidget {
  const _CreativeClassicSlotLayout({
    required this.imageViewport,
    required this.framePath,
    required this.size,
  });

  final Widget imageViewport;
  final Path framePath;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final double innerInset = (math.min(size.width, size.height) * 0.16)
        .clamp(2.5, 8)
        .toDouble();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipPath(
          clipper: _CreativePathClipper(framePath),
          child: const ColoredBox(color: AppColors.colorF8F1DD),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(innerInset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.stampverseBorderSoft.withValues(alpha: 0.4),
                border: Border.all(
                  color: AppColors.stampversePrimaryText.withValues(
                    alpha: 0.78,
                  ),
                  width: 0.8,
                ),
              ),
              child: imageViewport,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreativePathClipper extends CustomClipper<Path> {
  const _CreativePathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _CreativePathClipper oldClipper) {
    return oldClipper.path != path;
  }
}

class _CreativeTemplateFrameBorderPainter extends CustomPainter {
  const _CreativeTemplateFrameBorderPainter({
    required this.path,
    required this.borderColor,
  });

  final Path path;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(
    covariant _CreativeTemplateFrameBorderPainter oldDelegate,
  ) {
    return oldDelegate.path != path || oldDelegate.borderColor != borderColor;
  }
}

class _CreativeTemplateSlotImageViewport extends StatelessWidget {
  const _CreativeTemplateSlotImageViewport({
    required this.imageUrl,
    required this.scale,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
    required this.rotation,
  });

  final String imageUrl;
  final double scale;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final Offset panOffset = Offset(width * offsetX, height * offsetY);
          final double safeScale = scale.isFinite ? scale.clamp(0.2, 8) : 1;
          final double safeScaleX = scaleX.isFinite ? scaleX.clamp(0.2, 8) : 1;
          final double safeScaleY = scaleY.isFinite ? scaleY.clamp(0.2, 8) : 1;
          final double effectiveScaleX = (safeScale * safeScaleX)
              .clamp(0.2, 8.0)
              .toDouble();
          final double effectiveScaleY = (safeScale * safeScaleY)
              .clamp(0.2, 8.0)
              .toDouble();
          final double safeRotation = rotation.isFinite ? rotation : 0;

          return Transform.translate(
            offset: panOffset,
            child: Transform.rotate(
              angle: safeRotation,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  effectiveScaleX,
                  effectiveScaleY,
                  1,
                ),
                child: SizedBox.expand(
                  child: _CreativeTemplateSlotImage(imageUrl: imageUrl),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreativeTemplateSlotImage extends StatelessWidget {
  const _CreativeTemplateSlotImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      final List<String> parts = imageUrl.split(',');
      if (parts.length > 1) {
        try {
          final Uint8List bytes = base64Decode(parts.last);
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
