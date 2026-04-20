import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
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
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

enum _ImportStampSource { collection, daily }

enum _TemplateImageSource { gallery, library }

class _TemplateSlotImageResult {
  const _TemplateSlotImageResult({
    required this.stampId,
    required this.imageUrl,
  });

  final String stampId;
  final String imageUrl;
}

class _TemplateImageAdjustResult {
  const _TemplateImageAdjustResult({
    required this.scale,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
    required this.rotation,
  });

  final double scale;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final double rotation;
}

class StampverseEditStudioController {
  Future<void> Function()? _openImportSheet;
  Future<Uint8List?> Function()? _captureBoardImage;

  Future<void> openImportSheet() async {
    final Future<void> Function()? action = _openImportSheet;
    if (action == null) return;
    await action();
  }

  Future<Uint8List?> captureBoardImage() async {
    final Future<Uint8List?> Function()? action = _captureBoardImage;
    if (action == null) return null;
    return action();
  }
}

class StampverseEditStudioView extends StatefulWidget {
  const StampverseEditStudioView({
    super.key,
    required this.boards,
    required this.activeBoardId,
    required this.stamps,
    required this.onSaveBoard,
    this.onCreateBoard,
    this.onSelectBoard,
    this.controller,
    this.showBoardHeader = true,
    this.enableAssetFrameOverlay = false,
  });

  final List<StampEditBoard> boards;
  final String? activeBoardId;
  final List<StampDataModel> stamps;
  final VoidCallback? onCreateBoard;
  final ValueChanged<String>? onSelectBoard;
  final ValueChanged<StampEditBoard> onSaveBoard;
  final StampverseEditStudioController? controller;
  final bool showBoardHeader;
  final bool enableAssetFrameOverlay;

  @override
  State<StampverseEditStudioView> createState() =>
      _StampverseEditStudioViewState();
}

class _StampverseEditStudioViewState extends State<StampverseEditStudioView> {
  static const double _kEditLayerBaseWidth = 116;
  static const double _kEditLayerMinScale = 0.35;
  static const double _kEditLayerMaxScale = 4;
  static const double _kEditLayerViewportPaddingRatio = 0.01;
  static const double _kEditLayerGesturePadding = 28;
  static const double _kTemplateSlotMinRatio = 0.12;
  static const double _kTemplateSlotMaxRatio = 0.96;
  static const double _kTemplateDuplicateOffset = 0.04;
  static const double _kTemplateToolbarWidth = 206;
  static const double _kTemplateToolbarHeight = 44;
  static const double _kTemplateToolbarGap = 10;
  static const double _kTemplateToolbarCanvasPadding = 8;

  StampEditBoard? _workingBoard;
  String? _selectedLayerId;
  _LayerGestureSession? _gestureSession;
  final GlobalKey _trashZoneKey = GlobalKey();
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  bool _isTrashHovering = false;
  bool _hideTemplateAddActionForCapture = false;
  bool _isCapturingBoardImage = false;

  @override
  void initState() {
    super.initState();
    _syncBoardFromWidget(force: true);
    _bindController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant StampverseEditStudioView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBoardFromWidget(force: false);
    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller);
      _bindController(widget.controller);
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    super.dispose();
  }

  void _bindController(StampverseEditStudioController? controller) {
    if (controller == null) return;
    controller._openImportSheet = _openImportSheet;
    controller._captureBoardImage = _captureBoardImage;
  }

  void _unbindController(StampverseEditStudioController? controller) {
    if (controller?._openImportSheet == _openImportSheet) {
      controller?._openImportSheet = null;
    }
    if (controller?._captureBoardImage == _captureBoardImage) {
      controller?._captureBoardImage = null;
    }
  }

  void _syncBoardFromWidget({required bool force}) {
    final StampEditBoard? activeBoard = _resolveActiveBoard(
      widget.boards,
      widget.activeBoardId,
    );
    if (activeBoard == null) {
      _workingBoard = null;
      _selectedLayerId = null;
      return;
    }

    final StampEditBoard? current = _workingBoard;
    final bool shouldReplace =
        force ||
        current == null ||
        current.id != activeBoard.id ||
        current.updatedAt != activeBoard.updatedAt;

    if (shouldReplace) {
      _workingBoard = activeBoard;
      final bool stillExists = activeBoard.layers.any(
        (StampEditLayer layer) => layer.id == _selectedLayerId,
      );
      if (!stillExists) {
        _selectedLayerId = null;
      }
    }
  }

  static StampEditBoard? _resolveActiveBoard(
    List<StampEditBoard> boards,
    String? activeId,
  ) {
    if (boards.isEmpty) return null;
    if (activeId == null || activeId.isEmpty) {
      return boards.first;
    }

    for (final StampEditBoard board in boards) {
      if (board.id == activeId) return board;
    }
    return boards.first;
  }

  void _setBoard(StampEditBoard nextBoard, {required bool persist}) {
    setState(() {
      _workingBoard = nextBoard;
    });
    if (persist) {
      widget.onSaveBoard(nextBoard);
    }
  }

  bool _isTemplateBoard(StampEditBoard board) {
    return board.editorMode == StampEditBoardEditorMode.template;
  }

  Color _resolveCanvasColor(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return AppColors.white;
    final String rawColor = board.templateCanvasColorHex?.trim() ?? '';
    if (rawColor.isEmpty) return AppColors.white;
    try {
      return AppColors.fromHex(rawColor);
    } catch (_) {
      return AppColors.white;
    }
  }

  bool _useLightClassicInnerBorder(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return false;
    final String templateId = (board.templateId ?? '').toLowerCase();
    if (templateId.contains('night')) return true;
    return _resolveCanvasColor(board).computeLuminance() < 0.2;
  }

  bool _useScallopedClassicFrameForTemplate(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return false;
    final String templateId = (board.templateId ?? '').trim().toLowerCase();
    return templateId == 'template_night_stamp_collage_v2';
  }

  bool _usePerforatedScallopStyleForTemplate(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return false;
    final String templateId = (board.templateId ?? '').trim().toLowerCase();
    if (templateId == 'template_botanical_postage_v4') return true;
    final String bgPath = (board.templateBackgroundAssetPath ?? '')
        .trim()
        .toLowerCase();
    return bgPath ==
        AppAssets.creativeTemplateBackgroundTemplate4Png.toLowerCase();
  }

  bool _useRetroPatchworkScallopStyleForTemplate(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return false;
    final String templateId = (board.templateId ?? '').trim().toLowerCase();
    if (templateId == 'template_retro_postage_patchwork_v3') return true;
    final String bgPath = (board.templateBackgroundAssetPath ?? '')
        .trim()
        .toLowerCase();
    return bgPath ==
        AppAssets.creativeTemplateBackgroundTemplate3Png.toLowerCase();
  }

  bool _useClassicWallV5PerforationStyleForTemplate(StampEditBoard _) {
    return false;
  }

  bool _useClassicWallV6StyleForTemplate(StampEditBoard board) {
    if (!_isTemplateBoard(board)) return false;
    final String templateId = (board.templateId ?? '').trim().toLowerCase();
    return templateId == 'template_classic_stamp_wall_v6';
  }

  double _resolveTemplateCanvasCornerRadius(StampEditBoard board) {
    if (_useClassicWallV6StyleForTemplate(board)) {
      return 0;
    }
    return 18;
  }

  Color _resolveTemplateCanvasBorderColor(StampEditBoard board) {
    if (_useClassicWallV6StyleForTemplate(board)) {
      return AppColors.transparent;
    }
    return AppColors.stampverseBorderSoft;
  }

  Size _resolveCanvasSize({
    required StampEditBoard board,
    required Size availableSize,
  }) {
    if (!_isTemplateBoard(board)) return availableSize;
    final double? sourceWidth = board.templateSourceWidth;
    final double? sourceHeight = board.templateSourceHeight;
    if (sourceWidth == null || sourceHeight == null) return availableSize;
    if (sourceWidth <= 0 || sourceHeight <= 0) return availableSize;

    final double aspectRatio = sourceWidth / sourceHeight;
    if (!aspectRatio.isFinite || aspectRatio <= 0) return availableSize;

    double width = availableSize.width;
    double height = width / aspectRatio;
    if (height > availableSize.height) {
      height = availableSize.height;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }

  StampEditLayer? _selectedLayer(StampEditBoard board) {
    final String? selectedId = _selectedLayerId;
    if (selectedId == null || selectedId.isEmpty) return null;
    for (final StampEditLayer layer in board.layers) {
      if (layer.id == selectedId) return layer;
    }
    return null;
  }

  void _clearSelection() {
    if (_selectedLayerId == null) return;
    setState(() {
      _selectedLayerId = null;
    });
  }

  bool _isInsideCanvas(Offset globalPosition) {
    final BuildContext? boundaryContext = _canvasBoundaryKey.currentContext;
    if (boundaryContext == null) return false;
    final RenderObject? renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final Rect canvasRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return canvasRect.contains(globalPosition);
  }

  void _handleRootPointerDown(PointerDownEvent event) {
    if (_selectedLayerId == null) return;
    if (_isInsideCanvas(event.position)) return;
    _clearSelection();
  }

  StampEditLayer? _selectedTemplateLayer(StampEditBoard board) {
    final StampEditLayer? selected = _selectedLayer(board);
    if (selected == null) return null;
    if (selected.layerType != StampEditLayerType.templateSlot) return null;
    return selected;
  }

  double _templateWidthRatio(StampEditLayer layer) {
    final double value = layer.widthRatio ?? 0.32;
    return value.clamp(_kTemplateSlotMinRatio, _kTemplateSlotMaxRatio);
  }

  double _templateHeightRatio(StampEditLayer layer) {
    final double value = layer.heightRatio ?? 0.24;
    return value.clamp(_kTemplateSlotMinRatio, _kTemplateSlotMaxRatio);
  }

  bool _layerHasImage(StampEditLayer layer) {
    return layer.imageUrl.trim().isNotEmpty;
  }

  void _selectLayer(String layerId, {bool bringToFront = true}) {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;

    List<StampEditLayer> layers = board.layers;
    if (bringToFront) {
      final int index = layers.indexWhere(
        (StampEditLayer layer) => layer.id == layerId,
      );
      if (index >= 0 && index != layers.length - 1) {
        final List<StampEditLayer> updated = List<StampEditLayer>.from(layers);
        final StampEditLayer layer = updated.removeAt(index);
        updated.add(layer);
        layers = updated;
        _setBoard(board.copyWith(layers: layers), persist: true);
      }
    }

    setState(() {
      _selectedLayerId = layerId;
    });
  }

  void _updateLayer({
    required String layerId,
    required StampEditLayer Function(StampEditLayer current) mapper,
    required bool persist,
  }) {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;

    final int index = board.layers.indexWhere(
      (StampEditLayer layer) => layer.id == layerId,
    );
    if (index < 0) return;

    final List<StampEditLayer> updatedLayers = List<StampEditLayer>.from(
      board.layers,
    );
    updatedLayers[index] = mapper(updatedLayers[index]);
    _setBoard(board.copyWith(layers: updatedLayers), persist: persist);
  }

  void _onLayerScaleStart(
    StampEditLayer layer,
    ScaleStartDetails details,
    Size canvasSize,
  ) {
    _selectLayer(layer.id, bringToFront: true);
    if (layer.isLocked) return;

    _gestureSession = _LayerGestureSession(
      layerId: layer.id,
      layerType: layer.layerType,
      initialFocalPoint: details.focalPoint,
      initialCenterX: layer.centerX,
      initialCenterY: layer.centerY,
      initialScale: layer.scale,
      initialRotation: layer.rotation,
      initialWidthRatio: _templateWidthRatio(layer),
      initialHeightRatio: _templateHeightRatio(layer),
      canvasSize: canvasSize,
      currentFocalPoint: details.focalPoint,
    );
    _setTrashHovering(_isPointOverTrash(details.focalPoint));
  }

  void _onLayerScaleUpdate(ScaleUpdateDetails details) {
    final _LayerGestureSession? session = _gestureSession;
    if (session == null) return;

    final double canvasWidth = session.canvasSize.width;
    final double canvasHeight = session.canvasSize.height;
    if (canvasWidth <= 0 || canvasHeight <= 0) return;

    final double deltaX = _finiteOrZero(
      (details.focalPoint.dx - session.initialFocalPoint.dx) / canvasWidth,
    );
    final double deltaY = _finiteOrZero(
      (details.focalPoint.dy - session.initialFocalPoint.dy) / canvasHeight,
    );
    final double scaleFactor = _safeScaleFactor(details.scale);
    final double rotationDelta = _finiteOrZero(details.rotation);

    _updateLayer(
      layerId: session.layerId,
      persist: false,
      mapper: (StampEditLayer current) {
        if (session.layerType == StampEditLayerType.templateSlot) {
          final double nextWidthRatio =
              (session.initialWidthRatio * scaleFactor).clamp(
                _kTemplateSlotMinRatio,
                _kTemplateSlotMaxRatio,
              );
          final double nextHeightRatio =
              (session.initialHeightRatio * scaleFactor).clamp(
                _kTemplateSlotMinRatio,
                _kTemplateSlotMaxRatio,
              );
          final ({double minX, double maxX, double minY, double maxY})
          layerBounds = _computeTemplateLayerBounds(
            widthRatio: nextWidthRatio,
            heightRatio: nextHeightRatio,
          );

          return current.copyWith(
            centerX: _clampCenter(
              session.initialCenterX + deltaX,
              layerBounds.minX,
              layerBounds.maxX,
            ),
            centerY: _clampCenter(
              session.initialCenterY + deltaY,
              layerBounds.minY,
              layerBounds.maxY,
            ),
            widthRatio: nextWidthRatio,
            heightRatio: nextHeightRatio,
            rotation: session.initialRotation + rotationDelta,
          );
        }

        final double nextScale = (session.initialScale * scaleFactor).clamp(
          _kEditLayerMinScale,
          _kEditLayerMaxScale,
        );
        final ({double minX, double maxX, double minY, double maxY})
        layerBounds = _computeLayerBounds(
          shapeType: current.shapeType,
          scale: nextScale,
          canvasSize: session.canvasSize,
        );
        return current.copyWith(
          centerX: _clampCenter(
            session.initialCenterX + deltaX,
            layerBounds.minX,
            layerBounds.maxX,
          ),
          centerY: _clampCenter(
            session.initialCenterY + deltaY,
            layerBounds.minY,
            layerBounds.maxY,
          ),
          scale: nextScale,
          rotation: session.initialRotation + rotationDelta,
        );
      },
    );

    session.currentFocalPoint = details.focalPoint;
    _setTrashHovering(_isPointOverTrash(details.focalPoint));
  }

  double _finiteOrZero(double value) {
    return value.isFinite ? value : 0;
  }

  double _safeScaleFactor(double scaleFactor) {
    if (!scaleFactor.isFinite || scaleFactor <= 0) return 1;
    return scaleFactor;
  }

  double _clampCenter(double value, double min, double max) {
    if (min > max) return 0.5;
    final double safeValue = value.isFinite ? value : 0.5;
    return safeValue.clamp(min, max).toDouble();
  }

  ({double minX, double maxX, double minY, double maxY}) _computeLayerBounds({
    required StampShapeType shapeType,
    required double scale,
    required Size canvasSize,
  }) {
    final double layerWidth = _kEditLayerBaseWidth * scale;
    final double layerHeight =
        (_kEditLayerBaseWidth / shapeType.aspectRatio) * scale;

    final double halfWidthRatio = (layerWidth / 2) / canvasSize.width;
    final double halfHeightRatio = (layerHeight / 2) / canvasSize.height;

    final double minX = (halfWidthRatio + _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double maxX = (1 - halfWidthRatio - _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double minY = (halfHeightRatio + _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double maxY = (1 - halfHeightRatio - _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();

    return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  ({double minX, double maxX, double minY, double maxY})
  _computeTemplateLayerBounds({
    required double widthRatio,
    required double heightRatio,
  }) {
    final double halfWidthRatio = widthRatio / 2;
    final double halfHeightRatio = heightRatio / 2;

    final double minX = (halfWidthRatio + _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double maxX = (1 - halfWidthRatio - _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double minY = (halfHeightRatio + _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();
    final double maxY = (1 - halfHeightRatio - _kEditLayerViewportPaddingRatio)
        .clamp(0, 1)
        .toDouble();

    return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  Future<void> _onLayerScaleEnd(ScaleEndDetails details) async {
    final _LayerGestureSession? session = _gestureSession;
    _gestureSession = null;
    if (session == null) return;

    final bool droppedOnTrash = _isPointOverTrash(session.currentFocalPoint);
    _setTrashHovering(false);

    if (droppedOnTrash) {
      final bool shouldDelete = await _confirmDeleteLayer();
      if (!mounted) return;
      if (shouldDelete) {
        final StampEditBoard? board = _workingBoard;
        if (board == null) return;
        final List<StampEditLayer> updatedLayers = board.layers
            .where((StampEditLayer layer) => layer.id != session.layerId)
            .toList(growable: false);
        final StampEditBoard nextBoard = board.copyWith(layers: updatedLayers);
        setState(() {
          _workingBoard = nextBoard;
          if (_selectedLayerId == session.layerId) {
            _selectedLayerId = null;
          }
        });
        widget.onSaveBoard(nextBoard);
        return;
      }
    }

    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    widget.onSaveBoard(board);
  }

  void _setTrashHovering(bool value) {
    if (_isTrashHovering == value) return;
    setState(() {
      _isTrashHovering = value;
    });
  }

  bool _isPointOverTrash(Offset globalPoint) {
    final BuildContext? context = _trashZoneKey.currentContext;
    if (context == null) return false;
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final Offset topLeft = renderObject.localToGlobal(Offset.zero);
    final Rect bounds = topLeft & renderObject.size;
    return bounds.inflate(8).contains(globalPoint);
  }

  Future<bool> _confirmDeleteLayer() async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.stampverseSurface,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.stampverseDanger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.stampverseDanger,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  LocaleKey.stampverseEditTrashDeleteTitle.tr,
                  style: StampverseTextStyles.body(
                    color: AppColors.stampverseHeadingText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            LocaleKey.stampverseEditTrashDeleteBody.tr,
            style: StampverseTextStyles.body(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocaleKey.cancel.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                LocaleKey.stampverseEditTrashDeleteConfirm.tr,
                style: StampverseTextStyles.caption(
                  color: AppColors.stampverseDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return accepted ?? false;
  }

  Future<Uint8List?> _captureBoardImage() async {
    if (_isCapturingBoardImage) return null;
    _isCapturingBoardImage = true;

    if (mounted && !_hideTemplateAddActionForCapture) {
      setState(() {
        _hideTemplateAddActionForCapture = true;
      });
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final BuildContext? boundaryContext = _canvasBoundaryKey.currentContext;
      if (boundaryContext == null) return null;
      if (!boundaryContext.mounted) return null;
      final RenderObject? renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      final RenderRepaintBoundary boundary = renderObject;

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      _isCapturingBoardImage = false;
      if (mounted && _hideTemplateAddActionForCapture) {
        setState(() {
          _hideTemplateAddActionForCapture = false;
        });
      }
    }
  }

  void _addStampToBoard(StampDataModel stamp) {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;

    final StampEditLayer layer = StampEditLayer(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      stampId: stamp.id,
      imageUrl: stamp.imageUrl,
      shapeType: stamp.shapeType,
      centerX: 0.5,
      centerY: 0.5,
      scale: 1,
      rotation: 0,
    );

    final List<StampEditLayer> updatedLayers = <StampEditLayer>[
      ...board.layers,
      layer,
    ];
    setState(() {
      _selectedLayerId = layer.id;
    });
    _setBoard(board.copyWith(layers: updatedLayers), persist: true);
  }

  Future<void> _onTemplateLayerTap(StampEditLayer layer) async {
    final bool wasSelected = _selectedLayerId == layer.id;
    _selectLayer(layer.id, bringToFront: true);
    if (!wasSelected) return;
    await _pickTemplateImageForLayer(layer.id);
  }

  Future<void> _pickTemplateImageForLayer(String layerId) async {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    final int layerIndex = board.layers.indexWhere(
      (StampEditLayer layer) => layer.id == layerId,
    );
    if (layerIndex < 0) return;

    final _TemplateSlotImageResult? picked = await _pickTemplateSlotImage();
    if (picked == null) return;

    _updateLayer(
      layerId: layerId,
      persist: true,
      mapper: (StampEditLayer current) {
        return current.copyWith(
          stampId: picked.stampId,
          imageUrl: picked.imageUrl,
          shapeType: StampShapeType.square,
          contentScale: 1,
          contentScaleX: 1,
          contentScaleY: 1,
          contentOffsetX: 0,
          contentOffsetY: 0,
          contentRotation: 0,
        );
      },
    );
  }

  Future<_TemplateSlotImageResult?> _pickTemplateSlotImage() async {
    final _TemplateImageSource? source =
        await showModalBottomSheet<_TemplateImageSource>(
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
                      Icons.photo_library_outlined,
                      color: AppColors.stampversePrimaryText,
                    ),
                    title: Text(
                      LocaleKey.stampverseEditTemplateSourceGallery.tr,
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_TemplateImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.style_outlined,
                      color: AppColors.stampversePrimaryText,
                    ),
                    title: Text(LocaleKey.stampverseEditTemplateSourceStamp.tr),
                    onTap: () =>
                        Navigator.of(context).pop(_TemplateImageSource.library),
                  ),
                ],
              ),
            );
          },
        );

    if (source == null) return null;
    if (source == _TemplateImageSource.gallery) {
      return _pickTemplateImageFromGallery();
    }
    return _pickTemplateImageFromLibrary();
  }

  Future<_TemplateSlotImageResult?> _pickTemplateImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null) return null;

      final String extension = file.path.toLowerCase();
      final String mimeType = extension.endsWith('.png') ? 'png' : 'jpeg';
      final List<int> bytes = await file.readAsBytes();
      final String encoded = base64Encode(bytes);
      return _TemplateSlotImageResult(
        stampId: 'gallery_${DateTime.now().microsecondsSinceEpoch}',
        imageUrl: 'data:image/$mimeType;base64,$encoded',
      );
    } catch (_) {
      return null;
    }
  }

  Future<_TemplateSlotImageResult?> _pickTemplateImageFromLibrary() async {
    final StampDataModel? picked = await showModalBottomSheet<StampDataModel>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.stampverseSurface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        if (widget.stamps.isEmpty) {
          return SafeArea(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  LocaleKey.stampverseHomeEditImportEmpty.tr,
                  textAlign: TextAlign.center,
                  style: StampverseTextStyles.body(),
                ),
              ),
            ),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.75,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      LocaleKey.stampverseEditTemplateSourceStamp.tr,
                      style: StampverseTextStyles.body(
                        color: AppColors.stampverseHeadingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3 / 4,
                          ),
                      itemCount: widget.stamps.length,
                      itemBuilder: (_, int index) {
                        final StampDataModel stamp = widget.stamps[index];
                        return GestureDetector(
                          key: ValueKey<String>(
                            'template-library-stamp-${stamp.id}',
                          ),
                          onTap: () => Navigator.of(context).pop(stamp),
                          child: StampverseStamp(
                            imageUrl: stamp.imageUrl,
                            shapeType: stamp.shapeType,
                            applyShapeClip: false,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked == null) return null;
    return _TemplateSlotImageResult(
      stampId: picked.id,
      imageUrl: picked.sourceImageUrl,
    );
  }

  void _deleteSelectedTemplateLayer() {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    final StampEditLayer? selected = _selectedTemplateLayer(board);
    if (selected == null) return;

    final List<StampEditLayer> nextLayers = board.layers
        .where((StampEditLayer layer) => layer.id != selected.id)
        .toList(growable: false);
    setState(() {
      _selectedLayerId = null;
    });
    _setBoard(board.copyWith(layers: nextLayers), persist: true);
  }

  void _duplicateSelectedTemplateLayer() {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    final StampEditLayer? selected = _selectedTemplateLayer(board);
    if (selected == null) return;

    final double widthRatio = _templateWidthRatio(selected);
    final double heightRatio = _templateHeightRatio(selected);
    final ({double minX, double maxX, double minY, double maxY}) bounds =
        _computeTemplateLayerBounds(
          widthRatio: widthRatio,
          heightRatio: heightRatio,
        );
    final StampEditLayer duplicated = selected.copyWith(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      centerX: _clampCenter(
        selected.centerX + _kTemplateDuplicateOffset,
        bounds.minX,
        bounds.maxX,
      ),
      centerY: _clampCenter(
        selected.centerY + _kTemplateDuplicateOffset,
        bounds.minY,
        bounds.maxY,
      ),
      isLocked: false,
    );

    final List<StampEditLayer> nextLayers = <StampEditLayer>[
      ...board.layers,
      duplicated,
    ];
    setState(() {
      _selectedLayerId = duplicated.id;
    });
    _setBoard(board.copyWith(layers: nextLayers), persist: true);
  }

  void _toggleLockSelectedTemplateLayer() {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    final StampEditLayer? selected = _selectedTemplateLayer(board);
    if (selected == null) return;

    _updateLayer(
      layerId: selected.id,
      persist: true,
      mapper: (StampEditLayer current) {
        return current.copyWith(isLocked: !current.isLocked);
      },
    );
  }

  Future<void> _editSelectedTemplateLayerImage() async {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    final StampEditLayer? selected = _selectedTemplateLayer(board);
    if (selected == null) return;

    if (!_layerHasImage(selected)) {
      await _pickTemplateImageForLayer(selected.id);
      return;
    }

    final _TemplateImageAdjustResult? result =
        await showModalBottomSheet<_TemplateImageAdjustResult>(
          context: context,
          isScrollControlled: true,
          enableDrag: false,
          backgroundColor: AppColors.transparent,
          builder: (_) {
            return FractionallySizedBox(
              heightFactor: 0.95,
              child: _TemplateImageAdjustSheet(
                imageUrl: selected.imageUrl,
                frameShape: selected.frameShape,
                slotAspectRatio:
                    _templateWidthRatio(selected) /
                    _templateHeightRatio(selected),
                initialScale: selected.contentScale,
                initialScaleX: selected.contentScaleX,
                initialScaleY: selected.contentScaleY,
                initialOffsetX: selected.contentOffsetX,
                initialOffsetY: selected.contentOffsetY,
                initialRotation: selected.contentRotation,
                enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
                useLightClassicInnerBorder: _useLightClassicInnerBorder(board),
                useScallopedClassicFrame: _useScallopedClassicFrameForTemplate(
                  board,
                ),
                usePerforatedScallopStyle:
                    _usePerforatedScallopStyleForTemplate(board),
                useRetroPatchworkScallopStyle:
                    _useRetroPatchworkScallopStyleForTemplate(board),
                useClassicWallV5PerforationStyle:
                    _useClassicWallV5PerforationStyleForTemplate(board),
                useClassicWallV6Style: _useClassicWallV6StyleForTemplate(board),
              ),
            );
          },
        );

    if (!mounted || result == null) return;

    _updateLayer(
      layerId: selected.id,
      persist: true,
      mapper: (StampEditLayer current) {
        return current.copyWith(
          contentScale: result.scale,
          contentScaleX: result.scaleX,
          contentScaleY: result.scaleY,
          contentOffsetX: result.offsetX,
          contentOffsetY: result.offsetY,
          contentRotation: result.rotation,
        );
      },
    );
  }

  Rect _resolveTemplateToolbarRect({
    required StampEditLayer layer,
    required Size canvasSize,
  }) {
    final double slotHeight = canvasSize.height * _templateHeightRatio(layer);
    final double centerX = layer.centerX * canvasSize.width;
    final double centerY = layer.centerY * canvasSize.height;

    final double minLeft = _kTemplateToolbarCanvasPadding;
    final double maxLeft = math.max(
      minLeft,
      canvasSize.width -
          _kTemplateToolbarWidth -
          _kTemplateToolbarCanvasPadding,
    );
    final double left = (centerX - (_kTemplateToolbarWidth / 2)).clamp(
      minLeft,
      maxLeft,
    );

    final double preferredTop =
        centerY -
        (slotHeight / 2) -
        _kTemplateToolbarGap -
        _kTemplateToolbarHeight;
    final double fallbackTop =
        centerY + (slotHeight / 2) + _kTemplateToolbarGap;
    final double minTop = _kTemplateToolbarCanvasPadding;
    final double maxTop = math.max(
      minTop,
      canvasSize.height -
          _kTemplateToolbarHeight -
          _kTemplateToolbarCanvasPadding,
    );
    final double unclampedTop = preferredTop >= minTop
        ? preferredTop
        : fallbackTop;
    final double top = unclampedTop.clamp(minTop, maxTop);

    return Rect.fromLTWH(
      left,
      top,
      _kTemplateToolbarWidth,
      _kTemplateToolbarHeight,
    );
  }

  String _dayKey(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _openImportSheet() async {
    final StampEditBoard? board = _workingBoard;
    if (board == null) return;
    if (_isTemplateBoard(board)) return;

    final List<String> collectionNames =
        widget.stamps
            .map((StampDataModel stamp) => stamp.album?.trim() ?? '')
            .where((String value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(
            (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
    final List<String> dayValues =
        widget.stamps
            .map((StampDataModel stamp) => stamp.parsedDate)
            .whereType<DateTime>()
            .map(_dayKey)
            .toSet()
            .toList(growable: false)
          ..sort((String a, String b) {
            final DateTime? dateA = DateFormat('dd/MM/yyyy').tryParse(a);
            final DateTime? dateB = DateFormat('dd/MM/yyyy').tryParse(b);
            if (dateA == null || dateB == null) {
              return b.compareTo(a);
            }
            return dateB.compareTo(dateA);
          });

    _ImportStampSource source = _ImportStampSource.collection;
    String? selectedCollection = collectionNames.isNotEmpty
        ? collectionNames.first
        : null;
    String? selectedDay = dayValues.isNotEmpty ? dayValues.first : null;

    final StampDataModel? picked = await showModalBottomSheet<StampDataModel>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.stampverseSurface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            final List<StampDataModel> filtered = widget.stamps
                .where((StampDataModel item) {
                  if (source == _ImportStampSource.collection) {
                    final String collection = item.album?.trim() ?? '';
                    if (selectedCollection == null ||
                        selectedCollection!.isEmpty) {
                      return false;
                    }
                    return collection == selectedCollection;
                  }

                  final DateTime? parsed = item.parsedDate;
                  if (parsed == null) return false;
                  if (selectedDay == null || selectedDay!.isEmpty) return false;
                  return _dayKey(parsed) == selectedDay;
                })
                .toList(growable: false);

            return FractionallySizedBox(
              heightFactor: 0.75,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _EditFilterChip(
                              label: LocaleKey
                                  .stampverseHomeEditSourceCollection
                                  .tr,
                              selected: source == _ImportStampSource.collection,
                              onTap: () {
                                setStateSheet(() {
                                  source = _ImportStampSource.collection;
                                  selectedCollection =
                                      collectionNames.isNotEmpty
                                      ? collectionNames.first
                                      : null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _EditFilterChip(
                              label: LocaleKey.stampverseHomeEditSourceDaily.tr,
                              selected: source == _ImportStampSource.daily,
                              onTap: () {
                                setStateSheet(() {
                                  source = _ImportStampSource.daily;
                                  selectedDay = dayValues.isNotEmpty
                                      ? dayValues.first
                                      : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          source == _ImportStampSource.collection
                              ? LocaleKey.stampverseHomeEditFilterCollection.tr
                              : LocaleKey.stampverseHomeEditFilterDaily.tr,
                          style: StampverseTextStyles.caption(
                            color: AppColors.stampverseMutedText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: source == _ImportStampSource.collection
                              ? collectionNames.length
                              : dayValues.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, int index) {
                            final String label =
                                source == _ImportStampSource.collection
                                ? collectionNames[index]
                                : dayValues[index];
                            final bool selected =
                                source == _ImportStampSource.collection
                                ? selectedCollection == label
                                : selectedDay == label;
                            return _EditFilterChip(
                              label: label,
                              selected: selected,
                              onTap: () {
                                setStateSheet(() {
                                  if (source == _ImportStampSource.collection) {
                                    selectedCollection = label;
                                  } else {
                                    selectedDay = label;
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  LocaleKey.stampverseHomeEditImportEmpty.tr,
                                  textAlign: TextAlign.center,
                                  style: StampverseTextStyles.body(),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 3 / 4,
                                    ),
                                itemCount: filtered.length,
                                itemBuilder: (_, int index) {
                                  final StampDataModel stamp = filtered[index];
                                  return GestureDetector(
                                    onTap: () =>
                                        Navigator.of(context).pop(stamp),
                                    child: StampverseStamp(
                                      imageUrl: stamp.imageUrl,
                                      shapeType: stamp.shapeType,
                                      applyShapeClip: false,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null) return;
    _addStampToBoard(picked);
  }

  Widget _buildFreeformLayer({
    required StampEditLayer layer,
    required Size canvasSize,
  }) {
    final double baseHeight =
        _kEditLayerBaseWidth / layer.shapeType.aspectRatio;
    final double scaledWidth = _kEditLayerBaseWidth * layer.scale;
    final double scaledHeight = baseHeight * layer.scale;
    final double gestureWidth = scaledWidth + (_kEditLayerGesturePadding * 2);
    final double gestureHeight = scaledHeight + (_kEditLayerGesturePadding * 2);
    final double left = (layer.centerX * canvasSize.width) - (gestureWidth / 2);
    final double top =
        (layer.centerY * canvasSize.height) - (gestureHeight / 2);

    return Positioned(
      key: ValueKey<String>('edit-layer-${layer.id}'),
      left: left,
      top: top,
      child: SizedBox(
        width: gestureWidth,
        height: gestureHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _selectLayer(layer.id),
          onScaleStart: (ScaleStartDetails details) {
            _onLayerScaleStart(layer, details, canvasSize);
          },
          onScaleUpdate: _onLayerScaleUpdate,
          onScaleEnd: _onLayerScaleEnd,
          child: Center(
            child: Transform.rotate(
              angle: layer.rotation,
              child: Transform.scale(
                scale: layer.scale,
                child: StampverseStamp(
                  imageUrl: layer.imageUrl,
                  shapeType: layer.shapeType,
                  applyShapeClip: false,
                  width: _kEditLayerBaseWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSlotLayer({
    required StampEditLayer layer,
    required Size canvasSize,
    required bool useLightClassicInnerBorder,
    required bool useScallopedClassicFrame,
    required bool usePerforatedScallopStyle,
    required bool useRetroPatchworkScallopStyle,
    required bool useClassicWallV5PerforationStyle,
    required bool useClassicWallV6Style,
  }) {
    final double widthRatio = _templateWidthRatio(layer);
    final double heightRatio = _templateHeightRatio(layer);
    final double slotWidth = canvasSize.width * widthRatio;
    final double slotHeight = canvasSize.height * heightRatio;
    final double gestureWidth = slotWidth + (_kEditLayerGesturePadding * 2);
    final double gestureHeight = slotHeight + (_kEditLayerGesturePadding * 2);
    final double left = (layer.centerX * canvasSize.width) - (gestureWidth / 2);
    final double top =
        (layer.centerY * canvasSize.height) - (gestureHeight / 2);
    final bool isSelected = _selectedLayerId == layer.id;

    return Positioned(
      key: ValueKey<String>('template-layer-${layer.id}'),
      left: left,
      top: top,
      child: SizedBox(
        width: gestureWidth,
        height: gestureHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _onTemplateLayerTap(layer);
          },
          onScaleStart: layer.isLocked
              ? null
              : (ScaleStartDetails details) {
                  _onLayerScaleStart(layer, details, canvasSize);
                },
          onScaleUpdate: layer.isLocked ? null : _onLayerScaleUpdate,
          onScaleEnd: layer.isLocked ? null : _onLayerScaleEnd,
          child: Center(
            child: Transform.rotate(
              angle: layer.rotation,
              child: _TemplateSlotSurface(
                key: ValueKey<String>('template-slot-surface-${layer.id}'),
                width: slotWidth,
                height: slotHeight,
                imageUrl: layer.imageUrl,
                showAddAction:
                    !_hideTemplateAddActionForCapture && !_layerHasImage(layer),
                isSelected: isSelected,
                isLocked: layer.isLocked,
                frameShape: layer.frameShape,
                enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
                imageScale: layer.contentScale,
                imageScaleX: layer.contentScaleX,
                imageScaleY: layer.contentScaleY,
                imageOffsetX: layer.contentOffsetX,
                imageOffsetY: layer.contentOffsetY,
                imageRotation: layer.contentRotation,
                useLightClassicInnerBorder: useLightClassicInnerBorder,
                useScallopedClassicFrame: useScallopedClassicFrame,
                usePerforatedScallopStyle: usePerforatedScallopStyle,
                useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
                useClassicWallV5PerforationStyle:
                    useClassicWallV5PerforationStyle,
                useClassicWallV6Style: useClassicWallV6Style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StampEditBoard? board = _workingBoard;
    if (board == null) {
      return StampverseEmptyTab(
        icon: Icons.edit_note_rounded,
        title: LocaleKey.stampverseHomeEditEmptyTitle.tr,
        subtitle: '',
        actionLabel: LocaleKey.stampverseHomeEditEmptyAction.tr,
        onActionTap: widget.onCreateBoard,
      );
    }
    final bool isTemplateBoard = _isTemplateBoard(board);
    final StampEditLayer? selectedTemplateLayer = isTemplateBoard
        ? _selectedTemplateLayer(board)
        : null;
    final String templateBackgroundAssetPath =
        board.templateBackgroundAssetPath?.trim() ?? '';
    final Color canvasColor = _resolveCanvasColor(board);
    final bool useLightClassicInnerBorder = _useLightClassicInnerBorder(board);
    final bool useScallopedClassicFrame = _useScallopedClassicFrameForTemplate(
      board,
    );
    final bool usePerforatedScallopStyle =
        _usePerforatedScallopStyleForTemplate(board);
    final bool useRetroPatchworkScallopStyle =
        _useRetroPatchworkScallopStyleForTemplate(board);
    final bool useClassicWallV5PerforationStyle =
        _useClassicWallV5PerforationStyleForTemplate(board);
    final bool useClassicWallV6Style = _useClassicWallV6StyleForTemplate(board);
    final double canvasCornerRadius = _resolveTemplateCanvasCornerRadius(board);
    final Color canvasBorderColor = _resolveTemplateCanvasBorderColor(board);

    final EdgeInsets contentPadding = widget.showBoardHeader
        ? const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            StampverseLayout.contentBottomPadding,
          )
        : const EdgeInsets.fromLTRB(8, 0, 8, 8);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleRootPointerDown,
      child: Padding(
        padding: contentPadding,
        child: Column(
          children: <Widget>[
            if (widget.showBoardHeader) ...<Widget>[
              Row(
                children: <Widget>[
                  Text(
                    LocaleKey.stampverseHomeEditBoards.tr,
                    style: StampverseTextStyles.caption(
                      color: AppColors.stampverseMutedText,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onCreateBoard,
                    child: Text(
                      LocaleKey.stampverseHomeEditCreateBoard.tr,
                      style: StampverseTextStyles.caption(
                        color: AppColors.colorF586AA6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.boards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, int index) {
                    final StampEditBoard item = widget.boards[index];
                    return _EditBoardChip(
                      title: item.name,
                      selected: item.id == board.id,
                      onTap: () => widget.onSelectBoard?.call(item.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (_, BoxConstraints constraints) {
                  final Size availableSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final Size canvasSize = _resolveCanvasSize(
                    board: board,
                    availableSize: availableSize,
                  );
                  final Rect? templateToolbarRect =
                      selectedTemplateLayer == null
                      ? null
                      : _resolveTemplateToolbarRect(
                          layer: selectedTemplateLayer,
                          canvasSize: canvasSize,
                        );

                  return Center(
                    child: SizedBox(
                      key: const ValueKey<String>('edit-board-canvas-box'),
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          RepaintBoundary(
                            key: _canvasBoundaryKey,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                canvasCornerRadius,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: canvasColor,
                                  border: Border.all(color: canvasBorderColor),
                                ),
                                child: Stack(
                                  children: <Widget>[
                                    Positioned.fill(
                                      child:
                                          isTemplateBoard &&
                                              board.backgroundStyle ==
                                                  StampEditBoardBackgroundStyle
                                                      .grid
                                          ? const SizedBox.shrink()
                                          : CustomPaint(
                                              painter:
                                                  StampverseEditBackgroundPainter(
                                                    backgroundStyle:
                                                        board.backgroundStyle,
                                                  ),
                                            ),
                                    ),
                                    if (isTemplateBoard &&
                                        templateBackgroundAssetPath.isNotEmpty)
                                      Positioned.fill(
                                        child: Image.asset(
                                          templateBackgroundAssetPath,
                                          fit: BoxFit.fill,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (_, _, _) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _clearSelection,
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    ...board.layers.map((StampEditLayer layer) {
                                      if (isTemplateBoard &&
                                          layer.layerType ==
                                              StampEditLayerType.templateSlot) {
                                        return _buildTemplateSlotLayer(
                                          layer: layer,
                                          canvasSize: canvasSize,
                                          useLightClassicInnerBorder:
                                              useLightClassicInnerBorder,
                                          useScallopedClassicFrame:
                                              useScallopedClassicFrame,
                                          usePerforatedScallopStyle:
                                              usePerforatedScallopStyle,
                                          useRetroPatchworkScallopStyle:
                                              useRetroPatchworkScallopStyle,
                                          useClassicWallV5PerforationStyle:
                                              useClassicWallV5PerforationStyle,
                                          useClassicWallV6Style:
                                              useClassicWallV6Style,
                                        );
                                      }
                                      return _buildFreeformLayer(
                                        layer: layer,
                                        canvasSize: canvasSize,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (selectedTemplateLayer != null &&
                              templateToolbarRect != null)
                            Positioned(
                              left: templateToolbarRect.left,
                              top: templateToolbarRect.top,
                              width: templateToolbarRect.width,
                              height: templateToolbarRect.height,
                              child: FittedBox(
                                alignment: Alignment.center,
                                fit: BoxFit.scaleDown,
                                child: _TemplateSlotToolbar(
                                  isLocked: selectedTemplateLayer.isLocked,
                                  onAdjustImage:
                                      _editSelectedTemplateLayerImage,
                                  onDelete: _deleteSelectedTemplateLayer,
                                  onDuplicate: _duplicateSelectedTemplateLayer,
                                  onToggleLock:
                                      _toggleLockSelectedTemplateLayer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // const SizedBox(height: 10),
            // Text(
            //   LocaleKey.stampverseHomeEditHint.tr,
            //   textAlign: TextAlign.center,
            //   style: StampverseTextStyles.caption(
            //     color: AppColors.stampverseMutedText,
            //   ),
            // ),
            if (!isTemplateBoard) ...<Widget>[
              const SizedBox(height: 6),
              _EditTrashDropZone(
                key: _trashZoneKey,
                highlighted: _isTrashHovering,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayerGestureSession {
  _LayerGestureSession({
    required this.layerId,
    required this.layerType,
    required this.initialFocalPoint,
    required this.initialCenterX,
    required this.initialCenterY,
    required this.initialScale,
    required this.initialRotation,
    required this.initialWidthRatio,
    required this.initialHeightRatio,
    required this.canvasSize,
    required this.currentFocalPoint,
  });

  final String layerId;
  final StampEditLayerType layerType;
  final Offset initialFocalPoint;
  final double initialCenterX;
  final double initialCenterY;
  final double initialScale;
  final double initialRotation;
  final double initialWidthRatio;
  final double initialHeightRatio;
  final Size canvasSize;
  Offset currentFocalPoint;
}

class _TemplateImageAdjustSheet extends StatefulWidget {
  const _TemplateImageAdjustSheet({
    required this.imageUrl,
    required this.frameShape,
    required this.slotAspectRatio,
    required this.initialScale,
    required this.initialScaleX,
    required this.initialScaleY,
    required this.initialOffsetX,
    required this.initialOffsetY,
    required this.initialRotation,
    required this.enableAssetFrameOverlay,
    required this.useLightClassicInnerBorder,
    required this.useScallopedClassicFrame,
    required this.usePerforatedScallopStyle,
    required this.useRetroPatchworkScallopStyle,
    required this.useClassicWallV5PerforationStyle,
    required this.useClassicWallV6Style,
  });

  final String imageUrl;
  final StampEditFrameShape frameShape;
  final double slotAspectRatio;
  final double initialScale;
  final double initialScaleX;
  final double initialScaleY;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialRotation;
  final bool enableAssetFrameOverlay;
  final bool useLightClassicInnerBorder;
  final bool useScallopedClassicFrame;
  final bool usePerforatedScallopStyle;
  final bool useRetroPatchworkScallopStyle;
  final bool useClassicWallV5PerforationStyle;
  final bool useClassicWallV6Style;

  @override
  State<_TemplateImageAdjustSheet> createState() =>
      _TemplateImageAdjustSheetState();
}

class _TemplateImageAdjustSheetState extends State<_TemplateImageAdjustSheet> {
  static const double _kMinScale = 0.5;
  static const double _kMaxScale = 6;
  static const double _kMinAxisScale = 0.4;
  static const double _kMaxAxisScale = 4;
  static const double _kMaxOffsetRatio = 1.8;
  static const double _kGuideOutsidePadding = 14;
  static const double _kHandleScaleStep = 0.0075;

  late double _scale;
  late double _scaleX;
  late double _scaleY;
  late double _offsetX;
  late double _offsetY;
  late double _rotation;

  double _scaleAtStart = 1;
  double _offsetXAtStart = 0;
  double _offsetYAtStart = 0;
  double _rotationAtStart = 0;
  Offset _focalPointAtStart = Offset.zero;
  Size _frameSize = const Size(1, 1);
  _TemplateGuideEdge? _activeGuideEdge;
  _TemplateGuideCorner? _activeGuideCorner;

  @override
  void initState() {
    super.initState();
    _scale = _normalizeScale(widget.initialScale);
    _scaleX = _normalizeAxisScale(widget.initialScaleX);
    _scaleY = _normalizeAxisScale(widget.initialScaleY);
    _offsetX = widget.initialOffsetX;
    _offsetY = widget.initialOffsetY;
    _rotation = widget.initialRotation;
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_activeGuideEdge != null || _activeGuideCorner != null) return;
    _scaleAtStart = _scale;
    _offsetXAtStart = _offsetX;
    _offsetYAtStart = _offsetY;
    _rotationAtStart = _rotation;
    _focalPointAtStart = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_activeGuideEdge != null || _activeGuideCorner != null) return;
    final double frameWidth = _frameSize.width <= 0 ? 1 : _frameSize.width;
    final double frameHeight = _frameSize.height <= 0 ? 1 : _frameSize.height;
    final Offset delta = details.focalPoint - _focalPointAtStart;
    final double scaleFactor = _safeScaleFactor(details.scale);

    final double nextScale = (_scaleAtStart * scaleFactor).clamp(
      _kMinScale,
      _kMaxScale,
    );
    final double nextOffsetX = (_offsetXAtStart + (delta.dx / frameWidth))
        .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
        .toDouble();
    final double nextOffsetY = (_offsetYAtStart + (delta.dy / frameHeight))
        .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
        .toDouble();
    final double nextRotation = _normalizeRotation(
      _rotationAtStart + details.rotation,
    );

    setState(() {
      _scale = nextScale.toDouble();
      _offsetX = nextOffsetX;
      _offsetY = nextOffsetY;
      _rotation = nextRotation;
    });
  }

  double _safeScaleFactor(double value) {
    if (!value.isFinite || value <= 0) return 1;
    return value;
  }

  double _normalizeRotation(double value) {
    if (!value.isFinite) return 0;
    const double fullTurn = math.pi * 2;
    double normalized = value % fullTurn;
    if (normalized > math.pi) {
      normalized -= fullTurn;
    } else if (normalized < -math.pi) {
      normalized += fullTurn;
    }
    return normalized;
  }

  Size _resolveFrameSize(Size availableSize) {
    final double safeAspect =
        widget.slotAspectRatio.isFinite && widget.slotAspectRatio > 0
        ? widget.slotAspectRatio
        : 1;
    final double minDimension = math.min(
      availableSize.width,
      availableSize.height,
    );
    final double maxWidth = (minDimension * 0.88)
        .clamp(170.0, 460.0)
        .toDouble();
    final double maxHeight = (availableSize.height * 0.72)
        .clamp(180.0, 560.0)
        .toDouble();

    double width = maxWidth;
    double height = width / safeAspect;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * safeAspect;
    }
    return Size(width, height);
  }

  ({double left, double top, double width, double height})
  _resolveImageViewportGeometry(Size frameSize) {
    if (widget.frameShape != StampEditFrameShape.stampClassic) {
      return (
        left: 0,
        top: 0,
        width: frameSize.width,
        height: frameSize.height,
      );
    }

    final double innerInset =
        (math.min(frameSize.width, frameSize.height) * 0.16)
            .clamp(5.0, 16.0)
            .toDouble();
    final double innerWidth = (frameSize.width - (innerInset * 2))
        .clamp(1.0, frameSize.width)
        .toDouble();
    final double innerHeight = (frameSize.height - (innerInset * 2))
        .clamp(1.0, frameSize.height)
        .toDouble();
    return (
      left: innerInset,
      top: innerInset,
      width: innerWidth,
      height: innerHeight,
    );
  }

  void _resetAdjustments() {
    setState(() {
      _scale = 1;
      _scaleX = 1;
      _scaleY = 1;
      _offsetX = 0;
      _offsetY = 0;
      _rotation = 0;
    });
  }

  double _normalizeScale(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(_kMinScale, _kMaxScale).toDouble();
  }

  double _normalizeAxisScale(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(_kMinAxisScale, _kMaxAxisScale).toDouble();
  }

  void _applyAxisScaleYDelta(double delta, {required bool anchorBottom}) {
    if (!delta.isFinite || delta == 0) return;
    final double previousScaleY = _scaleY;
    final double nextScaleY = _normalizeAxisScale(previousScaleY + delta);
    final double appliedDelta = nextScaleY - previousScaleY;
    if (appliedDelta == 0) return;

    final double offsetAdjustment = (anchorBottom ? -0.5 : 0.5) * appliedDelta;
    setState(() {
      _scaleY = nextScaleY;
      _offsetY = (_offsetY + offsetAdjustment)
          .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
          .toDouble();
    });
  }

  void _applyAxisScaleXDelta(double delta, {required bool anchorRight}) {
    if (!delta.isFinite || delta == 0) return;
    final double previousScaleX = _scaleX;
    final double nextScaleX = _normalizeAxisScale(previousScaleX + delta);
    final double appliedDelta = nextScaleX - previousScaleX;
    if (appliedDelta == 0) return;

    final double offsetAdjustment = (anchorRight ? -0.5 : 0.5) * appliedDelta;
    setState(() {
      _scaleX = nextScaleX;
      _offsetX = (_offsetX + offsetAdjustment)
          .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
          .toDouble();
    });
  }

  void _onTopHandleDrag(Offset delta) {
    _applyAxisScaleYDelta(-delta.dy * _kHandleScaleStep, anchorBottom: true);
  }

  void _onBottomHandleDrag(Offset delta) {
    _applyAxisScaleYDelta(delta.dy * _kHandleScaleStep, anchorBottom: false);
  }

  void _onLeftHandleDrag(Offset delta) {
    _applyAxisScaleXDelta(-delta.dx * _kHandleScaleStep, anchorRight: true);
  }

  void _onRightHandleDrag(Offset delta) {
    _applyAxisScaleXDelta(delta.dx * _kHandleScaleStep, anchorRight: false);
  }

  void _onCornerHandleDrag(_TemplateGuideCorner corner, Offset delta) {
    final double deltaX = switch (corner) {
      _TemplateGuideCorner.topLeft => -delta.dx,
      _TemplateGuideCorner.bottomLeft => -delta.dx,
      _TemplateGuideCorner.topRight => delta.dx,
      _TemplateGuideCorner.bottomRight => delta.dx,
    };
    final double deltaY = switch (corner) {
      _TemplateGuideCorner.topLeft => -delta.dy,
      _TemplateGuideCorner.topRight => -delta.dy,
      _TemplateGuideCorner.bottomLeft => delta.dy,
      _TemplateGuideCorner.bottomRight => delta.dy,
    };
    final bool anchorRight = switch (corner) {
      _TemplateGuideCorner.topLeft => true,
      _TemplateGuideCorner.bottomLeft => true,
      _TemplateGuideCorner.topRight => false,
      _TemplateGuideCorner.bottomRight => false,
    };
    final bool anchorBottom = switch (corner) {
      _TemplateGuideCorner.topLeft => true,
      _TemplateGuideCorner.topRight => true,
      _TemplateGuideCorner.bottomLeft => false,
      _TemplateGuideCorner.bottomRight => false,
    };

    final double previousScaleX = _scaleX;
    final double previousScaleY = _scaleY;
    final double nextScaleX = _normalizeAxisScale(
      previousScaleX + (deltaX * _kHandleScaleStep),
    );
    final double nextScaleY = _normalizeAxisScale(
      previousScaleY + (deltaY * _kHandleScaleStep),
    );
    final double appliedDeltaX = nextScaleX - previousScaleX;
    final double appliedDeltaY = nextScaleY - previousScaleY;
    if (appliedDeltaX == 0 && appliedDeltaY == 0) return;

    final double offsetAdjustmentX = (anchorRight ? -0.5 : 0.5) * appliedDeltaX;
    final double offsetAdjustmentY =
        (anchorBottom ? -0.5 : 0.5) * appliedDeltaY;
    setState(() {
      _scaleX = nextScaleX;
      _scaleY = nextScaleY;
      _offsetX = (_offsetX + offsetAdjustmentX)
          .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
          .toDouble();
      _offsetY = (_offsetY + offsetAdjustmentY)
          .clamp(-_kMaxOffsetRatio, _kMaxOffsetRatio)
          .toDouble();
    });
  }

  void _onEdgeHandleStateChanged(_TemplateGuideEdge? edge) {
    if (_activeGuideEdge == edge &&
        (edge == null || _activeGuideCorner == null)) {
      return;
    }
    setState(() {
      _activeGuideEdge = edge;
      if (edge != null) {
        _activeGuideCorner = null;
      }
    });
  }

  void _onCornerHandleStateChanged(_TemplateGuideCorner? corner) {
    if (_activeGuideCorner == corner &&
        (corner == null || _activeGuideEdge == null)) {
      return;
    }
    setState(() {
      _activeGuideCorner = corner;
      if (corner != null) {
        _activeGuideEdge = null;
      }
    });
  }

  void _saveAdjustments() {
    Navigator.of(context).pop(
      _TemplateImageAdjustResult(
        scale: _scale,
        scaleX: _scaleX,
        scaleY: _scaleY,
        offsetX: _offsetX,
        offsetY: _offsetY,
        rotation: _rotation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.stampverseBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: LocaleKey.cancel.tr,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      LocaleKey.stampverseEditTemplateAdjustImage.tr,
                      textAlign: TextAlign.center,
                      style: StampverseTextStyles.body(
                        color: AppColors.stampverseHeadingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveAdjustments,
                    child: Text(
                      LocaleKey.ok.tr,
                      style: StampverseTextStyles.caption(
                        color: AppColors.colorF586AA6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                LocaleKey.stampverseEditTemplateAdjustHint.tr,
                textAlign: TextAlign.center,
                style: StampverseTextStyles.caption(
                  color: AppColors.stampverseMutedText,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, BoxConstraints constraints) {
                    final Size frameSize = _resolveFrameSize(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    );
                    final ({
                      double left,
                      double top,
                      double width,
                      double height,
                    })
                    viewportGeometry = _resolveImageViewportGeometry(frameSize);
                    _frameSize = Size(
                      viewportGeometry.width,
                      viewportGeometry.height,
                    );

                    return Center(
                      child: SizedBox(
                        width: frameSize.width + (_kGuideOutsidePadding * 2),
                        height: frameSize.height + (_kGuideOutsidePadding * 2),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: _kGuideOutsidePadding,
                                top: _kGuideOutsidePadding,
                                width: frameSize.width,
                                height: frameSize.height,
                                child: _TemplateSlotSurface(
                                  width: frameSize.width,
                                  height: frameSize.height,
                                  imageUrl: widget.imageUrl,
                                  showAddAction: false,
                                  isSelected: true,
                                  isLocked: false,
                                  frameShape: widget.frameShape,
                                  enableAssetFrameOverlay:
                                      widget.enableAssetFrameOverlay,
                                  imageScale: _scale,
                                  imageScaleX: _scaleX,
                                  imageScaleY: _scaleY,
                                  imageOffsetX: _offsetX,
                                  imageOffsetY: _offsetY,
                                  imageRotation: _rotation,
                                  showLockBadge: false,
                                  useLightClassicInnerBorder:
                                      widget.useLightClassicInnerBorder,
                                  useScallopedClassicFrame:
                                      widget.useScallopedClassicFrame,
                                  usePerforatedScallopStyle:
                                      widget.usePerforatedScallopStyle,
                                  useRetroPatchworkScallopStyle:
                                      widget.useRetroPatchworkScallopStyle,
                                  useClassicWallV5PerforationStyle:
                                      widget.useClassicWallV5PerforationStyle,
                                  useClassicWallV6Style:
                                      widget.useClassicWallV6Style,
                                ),
                              ),
                              Positioned(
                                left:
                                    _kGuideOutsidePadding +
                                    viewportGeometry.left,
                                top:
                                    _kGuideOutsidePadding +
                                    viewportGeometry.top,
                                width: viewportGeometry.width,
                                height: viewportGeometry.height,
                                child: _TemplateAdjustImageGuideOverlay(
                                  width: viewportGeometry.width,
                                  height: viewportGeometry.height,
                                  scaleX: _scale * _scaleX,
                                  scaleY: _scale * _scaleY,
                                  offsetX: _offsetX,
                                  offsetY: _offsetY,
                                  rotation: _rotation,
                                  onTopHandleDrag: _onTopHandleDrag,
                                  onBottomHandleDrag: _onBottomHandleDrag,
                                  onLeftHandleDrag: _onLeftHandleDrag,
                                  onRightHandleDrag: _onRightHandleDrag,
                                  onCornerHandleDrag: _onCornerHandleDrag,
                                  onEdgeHandleStateChanged:
                                      _onEdgeHandleStateChanged,
                                  activeCorner: _activeGuideCorner,
                                  activeEdge: _activeGuideEdge,
                                  onCornerHandleStateChanged:
                                      _onCornerHandleStateChanged,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _resetAdjustments,
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  color: AppColors.stampversePrimaryText,
                ),
                label: Text(
                  LocaleKey.stampverseEditTemplateAdjustReset.tr,
                  style: StampverseTextStyles.caption(
                    color: AppColors.stampversePrimaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateSlotToolbar extends StatelessWidget {
  const _TemplateSlotToolbar({
    required this.isLocked,
    required this.onAdjustImage,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleLock,
  });

  final bool isLocked;
  final VoidCallback onAdjustImage;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stampverseBorderSoft),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.stampverseShadowCard,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onAdjustImage,
              tooltip: LocaleKey.stampverseEditTemplateAdjustImage.tr,
              icon: const Icon(
                Icons.crop_free_rounded,
                color: AppColors.stampversePrimaryText,
              ),
            ),
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              tooltip: LocaleKey.stampverseEditTemplateDelete.tr,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.stampversePrimaryText,
              ),
            ),
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onDuplicate,
              tooltip: LocaleKey.stampverseEditTemplateDuplicate.tr,
              icon: const Icon(
                Icons.copy_all_outlined,
                color: AppColors.stampversePrimaryText,
              ),
            ),
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onToggleLock,
              tooltip: isLocked
                  ? LocaleKey.stampverseEditTemplateUnlock.tr
                  : LocaleKey.stampverseEditTemplateLock.tr,
              icon: Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: AppColors.stampversePrimaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSlotSurface extends StatelessWidget {
  const _TemplateSlotSurface({
    super.key,
    required this.width,
    required this.height,
    required this.imageUrl,
    required this.showAddAction,
    required this.isSelected,
    required this.isLocked,
    required this.frameShape,
    required this.enableAssetFrameOverlay,
    this.imageScale = 1,
    this.imageScaleX = 1,
    this.imageScaleY = 1,
    this.imageOffsetX = 0,
    this.imageOffsetY = 0,
    this.imageRotation = 0,
    this.showLockBadge = true,
    this.useLightClassicInnerBorder = false,
    this.useScallopedClassicFrame = false,
    this.usePerforatedScallopStyle = false,
    this.useRetroPatchworkScallopStyle = false,
    this.useClassicWallV5PerforationStyle = false,
    this.useClassicWallV6Style = false,
  });

  final double width;
  final double height;
  final String imageUrl;
  final bool showAddAction;
  final bool isSelected;
  final bool isLocked;
  final StampEditFrameShape frameShape;
  final bool enableAssetFrameOverlay;
  final double imageScale;
  final double imageScaleX;
  final double imageScaleY;
  final double imageOffsetX;
  final double imageOffsetY;
  final double imageRotation;
  final bool showLockBadge;
  final bool useLightClassicInnerBorder;
  final bool useScallopedClassicFrame;
  final bool usePerforatedScallopStyle;
  final bool useRetroPatchworkScallopStyle;
  final bool useClassicWallV5PerforationStyle;
  final bool useClassicWallV6Style;

  String? _frameOverlayAssetPath() {
    if (!enableAssetFrameOverlay) return null;
    if (usePerforatedScallopStyle &&
        frameShape == StampEditFrameShape.stampScallop) {
      return null;
    }
    if (useRetroPatchworkScallopStyle &&
        frameShape == StampEditFrameShape.stampScallop) {
      return null;
    }
    if (useClassicWallV6Style &&
        frameShape == StampEditFrameShape.stampScallop) {
      return null;
    }
    switch (frameShape) {
      case StampEditFrameShape.stampScallop:
        return AppAssets.creativeTemplateStampFrameOverlayPng;
      case StampEditFrameShape.stampCircle:
      case StampEditFrameShape.stampSquare:
      case StampEditFrameShape.stampClassic:
      case StampEditFrameShape.plainRect:
      case StampEditFrameShape.plainCircle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool usePerforatedScallop =
        usePerforatedScallopStyle &&
        frameShape == StampEditFrameShape.stampScallop;
    final bool useRetroPatchworkScallop =
        useRetroPatchworkScallopStyle &&
        frameShape == StampEditFrameShape.stampScallop;
    final bool useClassicWallV5Style =
        useClassicWallV5PerforationStyle &&
        frameShape == StampEditFrameShape.stampClassic;
    final bool useClassicWallV6ScallopStyle =
        useClassicWallV6Style && frameShape == StampEditFrameShape.stampScallop;
    final bool useClassicWallV6PlainRectStyle =
        useClassicWallV6Style && frameShape == StampEditFrameShape.plainRect;
    final Color slotBackgroundColor = usePerforatedScallop
        ? AppColors.stampverseBorderSoft.withValues(alpha: 0.55)
        : useRetroPatchworkScallop
        ? AppColors.white.withValues(alpha: 0.64)
        : useClassicWallV5Style
        ? AppColors.white.withValues(alpha: 0.88)
        : useClassicWallV6ScallopStyle
        ? AppColors.colorF8F1DD.withValues(alpha: 0.92)
        : useClassicWallV6PlainRectStyle
        ? AppColors.colorF8F1DD.withValues(alpha: 0.92)
        : AppColors.stampverseBorderSoft.withValues(alpha: 0.36);
    final double borderWidth = isSelected
        ? 2
        : useClassicWallV6Style
        ? 1.05
        : (usePerforatedScallop || useClassicWallV5Style ? 1 : 1.2);
    final Color borderColor = isSelected
        ? AppColors.colorF586AA6
        : useClassicWallV6PlainRectStyle
        ? AppColors.stampversePrimaryText.withValues(alpha: 0.62)
        : useClassicWallV6ScallopStyle
        ? AppColors.stampversePrimaryText.withValues(alpha: 0.26)
        : frameShape == StampEditFrameShape.stampClassic
        ? (useClassicWallV5Style
              ? AppColors.white.withValues(alpha: 0.98)
              : useLightClassicInnerBorder
              ? AppColors.black.withValues(alpha: 0.88)
              : AppColors.stampversePrimaryText)
        : usePerforatedScallop
        ? AppColors.colorF8F1DD.withValues(alpha: 0.96)
        : useRetroPatchworkScallop
        ? AppColors.white.withValues(alpha: 0.96)
        : AppColors.white;
    final String? overlayAssetPath = _frameOverlayAssetPath();
    final bool showPainterBorder =
        overlayAssetPath == null && !useClassicWallV6ScallopStyle;
    final Color classicWallV6OuterBorderColor = isSelected
        ? AppColors.colorF586AA6
        : AppColors.stampversePrimaryText.withValues(alpha: 0.78);
    final double classicWallV6OuterBorderWidth = isSelected ? 1.35 : 1.1;
    final Color classicInnerBorderColor = useClassicWallV5Style
        ? AppColors.black.withValues(alpha: isSelected ? 0.25 : 0.2)
        : useLightClassicInnerBorder
        ? AppColors.white.withValues(alpha: isSelected ? 0.92 : 0.82)
        : AppColors.stampversePrimaryText.withValues(
            alpha: isSelected ? 0.92 : 0.82,
          );
    final double classicInnerBorderWidth = useClassicWallV5Style
        ? (isSelected ? 1.1 : 0.9)
        : useLightClassicInnerBorder
        ? (isSelected ? 1.2 : 1)
        : (isSelected ? 1.5 : 1.15);

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, constraints.maxHeight);
          final Rect frameRect = Offset.zero & size;
          final bool isClassicStamp =
              frameShape == StampEditFrameShape.stampClassic;
          final double classicInnerInset =
              (math.min(width, height) * (useClassicWallV5Style ? 0.11 : 0.16))
                  .clamp(
                    useClassicWallV5Style ? 4.0 : 5.0,
                    useClassicWallV5Style ? 12.0 : 16.0,
                  )
                  .toDouble();
          final double perforatedInnerInset = (math.min(width, height) * 0.07)
              .clamp(4.5, 9.5)
              .toDouble();
          final double perforatedInnerRadius = (math.min(width, height) * 0.05)
              .clamp(2.6, 4.8)
              .toDouble();
          final Color perforatedOuterColor = AppColors.colorF8F1DD.withValues(
            alpha: 0.98,
          );
          final Color perforatedInnerBorderColor = AppColors.black.withValues(
            alpha: isSelected ? 0.32 : 0.26,
          );
          final double perforatedInnerBorderWidth = isSelected ? 1.15 : 0.9;
          final double retroInnerInset = (math.min(width, height) * 0.13)
              .clamp(5.5, 10.5)
              .toDouble();
          final double retroInnerRadius = (math.min(width, height) * 0.012)
              .clamp(0.8, 2.1)
              .toDouble();
          final Color retroOuterColor = AppColors.white.withValues(alpha: 0.97);
          final Color retroInnerColor = AppColors.white.withValues(alpha: 0.86);
          final Color retroInnerBorderColor = AppColors.white.withValues(
            alpha: 0.92,
          );
          final double retroInnerBorderWidth = isSelected ? 1.25 : 0.95;
          final double classicWallV6InnerInset =
              (math.min(width, height) * 0.04).clamp(3.2, 5.0).toDouble();
          final Color classicWallV6InnerBorderColor = AppColors
              .stampversePrimaryText
              .withValues(alpha: 0.22);
          final double classicWallV6InnerBorderWidth = isSelected ? 1.1 : 0.9;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (useClassicWallV6ScallopStyle)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: classicWallV6OuterBorderColor,
                      width: classicWallV6OuterBorderWidth,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(classicWallV6InnerInset),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _buildTemplateFrameClip(
                          frameShape: StampEditFrameShape.stampScallop,
                          clipRect:
                              Offset.zero &
                              Size(
                                math.max(
                                  1.0,
                                  size.width - (classicWallV6InnerInset * 2),
                                ),
                                math.max(
                                  1.0,
                                  size.height - (classicWallV6InnerInset * 2),
                                ),
                              ),
                          useScallopedClassicFrame: false,
                          usePerforatedScallopStyle: false,
                          useRetroPatchworkScallopStyle: false,
                          useClassicWallV5PerforationStyle: false,
                          useClassicWallV6Style: true,
                          child: ColoredBox(
                            color: imageUrl.trim().isEmpty
                                ? AppColors.colorF8F1DD
                                : AppColors.white,
                            child: imageUrl.trim().isEmpty
                                ? null
                                : _TemplateSlotImageViewport(
                                    imageUrl: imageUrl,
                                    scale: imageScale,
                                    scaleX: imageScaleX,
                                    scaleY: imageScaleY,
                                    offsetX: imageOffsetX,
                                    offsetY: imageOffsetY,
                                    rotation: imageRotation,
                                  ),
                          ),
                        ),
                        CustomPaint(
                          painter: _TemplateInnerScallopBorderPainter(
                            color: classicWallV6InnerBorderColor,
                            borderWidth: classicWallV6InnerBorderWidth,
                            useClassicWallV6Style: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isClassicStamp ||
                  usePerforatedScallop ||
                  useRetroPatchworkScallop)
                _buildTemplateFrameClip(
                  frameShape: frameShape,
                  clipRect: frameRect,
                  useScallopedClassicFrame: useScallopedClassicFrame,
                  usePerforatedScallopStyle: usePerforatedScallopStyle,
                  useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
                  useClassicWallV5PerforationStyle:
                      useClassicWallV5PerforationStyle,
                  useClassicWallV6Style: useClassicWallV6Style,
                  child: ColoredBox(
                    color: isClassicStamp
                        ? (useClassicWallV5Style
                              ? AppColors.white.withValues(alpha: 0.96)
                              : AppColors.colorF8F1DD)
                        : useRetroPatchworkScallop
                        ? retroOuterColor
                        : perforatedOuterColor,
                  ),
                )
              else
                _buildTemplateFrameClip(
                  frameShape: frameShape,
                  clipRect: frameRect,
                  useScallopedClassicFrame: useScallopedClassicFrame,
                  usePerforatedScallopStyle: usePerforatedScallopStyle,
                  useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
                  useClassicWallV5PerforationStyle:
                      useClassicWallV5PerforationStyle,
                  useClassicWallV6Style: useClassicWallV6Style,
                  child: ColoredBox(
                    color: slotBackgroundColor,
                    child: imageUrl.trim().isEmpty
                        ? null
                        : _TemplateSlotImageViewport(
                            imageUrl: imageUrl,
                            scale: imageScale,
                            scaleX: imageScaleX,
                            scaleY: imageScaleY,
                            offsetX: imageOffsetX,
                            offsetY: imageOffsetY,
                            rotation: imageRotation,
                          ),
                  ),
                ),
              if (isClassicStamp)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(classicInnerInset),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: slotBackgroundColor,
                        border: Border.all(
                          color: classicInnerBorderColor,
                          width: classicInnerBorderWidth,
                        ),
                      ),
                      child: imageUrl.trim().isEmpty
                          ? null
                          : _TemplateSlotImageViewport(
                              imageUrl: imageUrl,
                              scale: imageScale,
                              scaleX: imageScaleX,
                              scaleY: imageScaleY,
                              offsetX: imageOffsetX,
                              offsetY: imageOffsetY,
                              rotation: imageRotation,
                            ),
                    ),
                  ),
                ),
              if (usePerforatedScallop)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(perforatedInnerInset),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        perforatedInnerRadius,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: slotBackgroundColor,
                          border: Border.all(
                            color: perforatedInnerBorderColor,
                            width: perforatedInnerBorderWidth,
                          ),
                        ),
                        child: imageUrl.trim().isEmpty
                            ? null
                            : _TemplateSlotImageViewport(
                                imageUrl: imageUrl,
                                scale: imageScale,
                                scaleX: imageScaleX,
                                scaleY: imageScaleY,
                                offsetX: imageOffsetX,
                                offsetY: imageOffsetY,
                                rotation: imageRotation,
                              ),
                      ),
                    ),
                  ),
                ),
              if (useRetroPatchworkScallop)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(retroInnerInset),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(retroInnerRadius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: retroInnerColor,
                          border: Border.all(
                            color: retroInnerBorderColor,
                            width: retroInnerBorderWidth,
                          ),
                        ),
                        child: imageUrl.trim().isEmpty
                            ? null
                            : _TemplateSlotImageViewport(
                                imageUrl: imageUrl,
                                scale: imageScale,
                                scaleX: imageScaleX,
                                scaleY: imageScaleY,
                                offsetX: imageOffsetX,
                                offsetY: imageOffsetY,
                                rotation: imageRotation,
                              ),
                      ),
                    ),
                  ),
                ),
              CustomPaint(
                painter: showPainterBorder
                    ? _TemplateSlotBorderPainter(
                        frameShape: frameShape,
                        useScallopedClassicFrame: useScallopedClassicFrame,
                        usePerforatedScallopStyle: usePerforatedScallopStyle,
                        useRetroPatchworkScallopStyle:
                            useRetroPatchworkScallopStyle,
                        useClassicWallV5PerforationStyle:
                            useClassicWallV5PerforationStyle,
                        useClassicWallV6Style: useClassicWallV6Style,
                        borderColor: borderColor,
                        borderWidth: borderWidth,
                      )
                    : null,
              ),
              if (useClassicWallV6Style && !useClassicWallV6ScallopStyle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(0.6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: classicWallV6OuterBorderColor,
                            width: classicWallV6OuterBorderWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (overlayAssetPath != null)
                IgnorePointer(
                  child: Image.asset(
                    overlayAssetPath,
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (showAddAction)
                const Center(
                  child: Icon(
                    Icons.add_circle_rounded,
                    size: 26,
                    color: AppColors.stampverseMutedText,
                  ),
                ),
              if (isLocked && showLockBadge)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: AppColors.stampverseMutedText,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Widget _buildTemplateFrameClip({
  required StampEditFrameShape frameShape,
  required Rect clipRect,
  required bool useScallopedClassicFrame,
  required bool usePerforatedScallopStyle,
  required bool useRetroPatchworkScallopStyle,
  required bool useClassicWallV5PerforationStyle,
  required bool useClassicWallV6Style,
  required Widget child,
}) {
  switch (frameShape) {
    case StampEditFrameShape.plainCircle:
      return ClipOval(child: child);
    case StampEditFrameShape.plainRect:
      return ClipRRect(
        borderRadius: BorderRadius.circular(useClassicWallV6Style ? 6 : 8),
        child: child,
      );
    case StampEditFrameShape.stampScallop:
    case StampEditFrameShape.stampCircle:
    case StampEditFrameShape.stampSquare:
    case StampEditFrameShape.stampClassic:
      return ClipPath(
        clipper: _TemplateSlotFrameClipper(
          frameShape: frameShape,
          clipRect: clipRect,
          useScallopedClassicFrame: useScallopedClassicFrame,
          usePerforatedScallopStyle: usePerforatedScallopStyle,
          useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
          useClassicWallV5PerforationStyle: useClassicWallV5PerforationStyle,
          useClassicWallV6Style: useClassicWallV6Style,
        ),
        child: child,
      );
  }
}

Path _buildTemplateFramePath({
  required StampEditFrameShape frameShape,
  required Rect rect,
  required bool useScallopedClassicFrame,
  required bool usePerforatedScallopStyle,
  required bool useRetroPatchworkScallopStyle,
  required bool useClassicWallV5PerforationStyle,
  required bool useClassicWallV6Style,
}) {
  if (useClassicWallV6Style && frameShape == StampEditFrameShape.plainRect) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
  }
  if (useClassicWallV6Style && frameShape == StampEditFrameShape.stampScallop) {
    return _buildClassicWallV6ScallopPath(rect);
  }
  if (useClassicWallV5PerforationStyle &&
      frameShape == StampEditFrameShape.stampClassic) {
    return _buildClassicWallV5PerforationPath(rect);
  }
  if (useRetroPatchworkScallopStyle &&
      frameShape == StampEditFrameShape.stampScallop) {
    return _buildRetroPatchworkScallopPath(rect);
  }
  if (usePerforatedScallopStyle &&
      frameShape == StampEditFrameShape.stampScallop) {
    return _buildDensePerforatedScallopPath(rect);
  }
  if (useScallopedClassicFrame &&
      frameShape == StampEditFrameShape.stampClassic) {
    return buildTemplateFramePath(
      frameShape: StampEditFrameShape.stampSquare,
      rect: rect,
    );
  }
  return buildTemplateFramePath(frameShape: frameShape, rect: rect);
}

Path _buildClassicWallV6ScallopPath(Rect rect) {
  if (rect.width <= 0 || rect.height <= 0) {
    return Path()..addRect(rect);
  }

  final double minEdge = math.min(rect.width, rect.height);
  final double notchRadius = (minEdge * 0.043).clamp(2.4, 4.8).toDouble();
  final int topCount = math.max(
    8,
    math.max(
      (rect.width / 12).round(),
      (rect.width / (notchRadius * 2.6)).round(),
    ),
  );
  final int sideCount = math.max(
    10,
    math.max(
      (rect.height / 12).round(),
      (rect.height / (notchRadius * 2.55)).round(),
    ),
  );

  final Path base = Path()..addRect(rect);
  final Path notches = Path();
  final double topStep = rect.width / (topCount + 1);
  final double sideStep = rect.height / (sideCount + 1);

  for (int index = 1; index <= topCount; index += 1) {
    final double x = rect.left + (topStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.top), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.bottom), radius: notchRadius),
    );
  }

  for (int index = 1; index <= sideCount; index += 1) {
    final double y = rect.top + (sideStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
    );
  }

  final Path scallopedPath = Path.combine(
    PathOperation.difference,
    base,
    notches,
  );
  final double cornerRadius = (notchRadius * 0.6).clamp(1.2, 3.2).toDouble();
  final Path cornerMask = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));

  return Path.combine(PathOperation.intersect, scallopedPath, cornerMask);
}

Path _buildDensePerforatedScallopPath(Rect rect) {
  if (rect.width <= 0 || rect.height <= 0) {
    return Path()..addRect(rect);
  }

  final double minEdge = math.min(rect.width, rect.height);
  final double notchRadius = (minEdge * 0.032).clamp(1.9, 3.9).toDouble();
  final int topCount = math.max(
    8,
    math.max(
      (rect.width / 10).round(),
      (rect.width / (notchRadius * 2.8)).round(),
    ),
  );
  final int sideCount = math.max(
    10,
    math.max(
      (rect.height / 10).round(),
      (rect.height / (notchRadius * 2.8)).round(),
    ),
  );

  final Path base = Path()..addRect(rect);
  final Path notches = Path();
  final double topStep = rect.width / (topCount + 1);
  final double sideStep = rect.height / (sideCount + 1);

  for (int index = 1; index <= topCount; index += 1) {
    final double x = rect.left + (topStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.top), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.bottom), radius: notchRadius),
    );
  }

  for (int index = 1; index <= sideCount; index += 1) {
    final double y = rect.top + (sideStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
    );
  }

  final Path perforatedPath = Path.combine(
    PathOperation.difference,
    base,
    notches,
  );
  final double cornerRadius = (notchRadius * 0.82)
      .clamp(1.2, minEdge / 9)
      .toDouble();
  final Path cornerMask = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
  return Path.combine(PathOperation.intersect, perforatedPath, cornerMask);
}

Path _buildClassicWallV5PerforationPath(Rect rect) {
  if (rect.width <= 0 || rect.height <= 0) {
    return Path()..addRect(rect);
  }

  final double minEdge = math.min(rect.width, rect.height);
  final double notchRadius = (minEdge * 0.044).clamp(2.1, 3.7).toDouble();
  final double cornerRadius = (minEdge * 0.014).clamp(0.8, 2.2).toDouble();
  final int topCount = math.max(
    8,
    math.max(
      (rect.width / 10).round(),
      (rect.width / (notchRadius * 2.05)).round(),
    ),
  );
  final int sideCount = math.max(
    8,
    math.max(
      (rect.height / 10).round(),
      (rect.height / (notchRadius * 2.05)).round(),
    ),
  );

  final Path base = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
  final Path notches = Path();
  final double topStep = rect.width / (topCount + 1);
  final double sideStep = rect.height / (sideCount + 1);

  for (int index = 1; index <= topCount; index += 1) {
    final double x = rect.left + (topStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.top), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(x, rect.bottom), radius: notchRadius),
    );
  }

  for (int index = 1; index <= sideCount; index += 1) {
    final double y = rect.top + (sideStep * index);
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
    );
    notches.addOval(
      Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
    );
  }

  return Path.combine(PathOperation.difference, base, notches);
}

Path _buildRetroPatchworkScallopPath(Rect rect) {
  if (rect.width <= 0 || rect.height <= 0) {
    return Path()..addRect(rect);
  }

  final double minEdge = math.min(rect.width, rect.height);
  final double toothDepth = (minEdge * 0.052).clamp(2.2, 4.8).toDouble();
  final double cornerRadius = (minEdge * 0.075)
      .clamp(toothDepth * 1.7, minEdge * 0.22)
      .toDouble();
  if ((cornerRadius * 2) >= rect.width || (cornerRadius * 2) >= rect.height) {
    return _buildDensePerforatedScallopPath(rect);
  }

  final double left = rect.left + cornerRadius;
  final double right = rect.right - cornerRadius;
  final double top = rect.top + cornerRadius;
  final double bottom = rect.bottom - cornerRadius;
  final double horizontalSpan = right - left;
  final double verticalSpan = bottom - top;

  final int horizontalTeeth = math.max(
    4,
    math.max(
      (horizontalSpan / 11).round(),
      (horizontalSpan / (toothDepth * 2.4)).round(),
    ),
  );
  final int verticalTeeth = math.max(
    6,
    math.max(
      (verticalSpan / 11).round(),
      (verticalSpan / (toothDepth * 2.4)).round(),
    ),
  );

  final double topStep = horizontalSpan / horizontalTeeth;
  final double sideStep = verticalSpan / verticalTeeth;
  final Path path = Path()..moveTo(left, rect.top);

  for (int index = 0; index < horizontalTeeth; index += 1) {
    final double segmentStart = left + (topStep * index);
    final double segmentEnd = segmentStart + topStep;
    path.lineTo(segmentStart + (topStep / 2), rect.top + toothDepth);
    path.lineTo(segmentEnd, rect.top);
  }

  path.arcToPoint(
    Offset(rect.right, top),
    radius: Radius.circular(cornerRadius),
    clockwise: true,
  );

  for (int index = 0; index < verticalTeeth; index += 1) {
    final double segmentStart = top + (sideStep * index);
    final double segmentEnd = segmentStart + sideStep;
    path.lineTo(rect.right - toothDepth, segmentStart + (sideStep / 2));
    path.lineTo(rect.right, segmentEnd);
  }

  path.arcToPoint(
    Offset(right, rect.bottom),
    radius: Radius.circular(cornerRadius),
    clockwise: true,
  );

  for (int index = 0; index < horizontalTeeth; index += 1) {
    final double segmentStart = right - (topStep * index);
    final double segmentEnd = segmentStart - topStep;
    path.lineTo(segmentStart - (topStep / 2), rect.bottom - toothDepth);
    path.lineTo(segmentEnd, rect.bottom);
  }

  path.arcToPoint(
    Offset(rect.left, bottom),
    radius: Radius.circular(cornerRadius),
    clockwise: true,
  );

  for (int index = 0; index < verticalTeeth; index += 1) {
    final double segmentStart = bottom - (sideStep * index);
    final double segmentEnd = segmentStart - sideStep;
    path.lineTo(rect.left + toothDepth, segmentStart - (sideStep / 2));
    path.lineTo(rect.left, segmentEnd);
  }

  path.arcToPoint(
    Offset(left, rect.top),
    radius: Radius.circular(cornerRadius),
    clockwise: true,
  );
  path.close();
  return path;
}

class _TemplateSlotFrameClipper extends CustomClipper<Path> {
  const _TemplateSlotFrameClipper({
    required this.frameShape,
    required this.clipRect,
    required this.useScallopedClassicFrame,
    required this.usePerforatedScallopStyle,
    required this.useRetroPatchworkScallopStyle,
    required this.useClassicWallV5PerforationStyle,
    required this.useClassicWallV6Style,
  });

  final StampEditFrameShape frameShape;
  final Rect clipRect;
  final bool useScallopedClassicFrame;
  final bool usePerforatedScallopStyle;
  final bool useRetroPatchworkScallopStyle;
  final bool useClassicWallV5PerforationStyle;
  final bool useClassicWallV6Style;

  @override
  Path getClip(Size size) {
    return _buildTemplateFramePath(
      frameShape: frameShape,
      rect: clipRect,
      useScallopedClassicFrame: useScallopedClassicFrame,
      usePerforatedScallopStyle: usePerforatedScallopStyle,
      useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
      useClassicWallV5PerforationStyle: useClassicWallV5PerforationStyle,
      useClassicWallV6Style: useClassicWallV6Style,
    );
  }

  @override
  bool shouldReclip(covariant _TemplateSlotFrameClipper oldClipper) {
    return oldClipper.frameShape != frameShape ||
        oldClipper.clipRect != clipRect ||
        oldClipper.useScallopedClassicFrame != useScallopedClassicFrame ||
        oldClipper.usePerforatedScallopStyle != usePerforatedScallopStyle ||
        oldClipper.useRetroPatchworkScallopStyle !=
            useRetroPatchworkScallopStyle ||
        oldClipper.useClassicWallV5PerforationStyle !=
            useClassicWallV5PerforationStyle ||
        oldClipper.useClassicWallV6Style != useClassicWallV6Style;
  }
}

class _TemplateSlotBorderPainter extends CustomPainter {
  const _TemplateSlotBorderPainter({
    required this.frameShape,
    required this.useScallopedClassicFrame,
    required this.usePerforatedScallopStyle,
    required this.useRetroPatchworkScallopStyle,
    required this.useClassicWallV5PerforationStyle,
    required this.useClassicWallV6Style,
    required this.borderColor,
    required this.borderWidth,
  });

  final StampEditFrameShape frameShape;
  final bool useScallopedClassicFrame;
  final bool usePerforatedScallopStyle;
  final bool useRetroPatchworkScallopStyle;
  final bool useClassicWallV5PerforationStyle;
  final bool useClassicWallV6Style;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect borderRect = (Offset.zero & size).deflate(borderWidth / 2);
    final Path borderPath = _buildTemplateFramePath(
      frameShape: frameShape,
      rect: borderRect,
      useScallopedClassicFrame: useScallopedClassicFrame,
      usePerforatedScallopStyle: usePerforatedScallopStyle,
      useRetroPatchworkScallopStyle: useRetroPatchworkScallopStyle,
      useClassicWallV5PerforationStyle: useClassicWallV5PerforationStyle,
      useClassicWallV6Style: useClassicWallV6Style,
    );
    final bool isClassicStamp = frameShape == StampEditFrameShape.stampClassic;
    final bool isPerforatedScallop =
        usePerforatedScallopStyle &&
        frameShape == StampEditFrameShape.stampScallop;
    final bool isClassicWallV5 =
        useClassicWallV5PerforationStyle &&
        frameShape == StampEditFrameShape.stampClassic;
    canvas.drawPath(
      borderPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isClassicWallV5
            ? math.max(0.95, borderWidth + 0.1)
            : isClassicStamp
            ? math.max(1.8, borderWidth + 0.5)
            : isPerforatedScallop
            ? math.max(0.9, borderWidth - 0.1)
            : borderWidth
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TemplateSlotBorderPainter oldDelegate) {
    return oldDelegate.frameShape != frameShape ||
        oldDelegate.useScallopedClassicFrame != useScallopedClassicFrame ||
        oldDelegate.usePerforatedScallopStyle != usePerforatedScallopStyle ||
        oldDelegate.useRetroPatchworkScallopStyle !=
            useRetroPatchworkScallopStyle ||
        oldDelegate.useClassicWallV5PerforationStyle !=
            useClassicWallV5PerforationStyle ||
        oldDelegate.useClassicWallV6Style != useClassicWallV6Style ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

class _TemplateInnerScallopBorderPainter extends CustomPainter {
  const _TemplateInnerScallopBorderPainter({
    required this.color,
    required this.borderWidth,
    required this.useClassicWallV6Style,
  });

  final Color color;
  final double borderWidth;
  final bool useClassicWallV6Style;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect borderRect = (Offset.zero & size).deflate(borderWidth / 2);
    if (borderRect.width <= 0 || borderRect.height <= 0) return;
    final Path path = _buildTemplateFramePath(
      frameShape: StampEditFrameShape.stampScallop,
      rect: borderRect,
      useScallopedClassicFrame: false,
      usePerforatedScallopStyle: false,
      useRetroPatchworkScallopStyle: false,
      useClassicWallV5PerforationStyle: false,
      useClassicWallV6Style: useClassicWallV6Style,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TemplateInnerScallopBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.useClassicWallV6Style != useClassicWallV6Style;
  }
}

enum _TemplateGuideCorner { topLeft, topRight, bottomLeft, bottomRight }

enum _TemplateGuideEdge { top, right, bottom, left }

class _TemplateAdjustImageGuideOverlay extends StatelessWidget {
  const _TemplateAdjustImageGuideOverlay({
    required this.width,
    required this.height,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
    required this.rotation,
    required this.onTopHandleDrag,
    required this.onBottomHandleDrag,
    required this.onLeftHandleDrag,
    required this.onRightHandleDrag,
    required this.onCornerHandleDrag,
    required this.onEdgeHandleStateChanged,
    required this.activeCorner,
    required this.activeEdge,
    required this.onCornerHandleStateChanged,
  });

  final double width;
  final double height;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final ValueChanged<Offset> onTopHandleDrag;
  final ValueChanged<Offset> onBottomHandleDrag;
  final ValueChanged<Offset> onLeftHandleDrag;
  final ValueChanged<Offset> onRightHandleDrag;
  final void Function(_TemplateGuideCorner corner, Offset delta)
  onCornerHandleDrag;
  final ValueChanged<_TemplateGuideEdge?> onEdgeHandleStateChanged;
  final _TemplateGuideCorner? activeCorner;
  final _TemplateGuideEdge? activeEdge;
  final ValueChanged<_TemplateGuideCorner?> onCornerHandleStateChanged;

  Widget _buildEdgeHandle({
    required String keyValue,
    required _TemplateGuideEdge edge,
    required double left,
    required double top,
    required double width,
    required double height,
    required ValueChanged<Offset> onDrag,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Listener(
        key: ValueKey<String>(keyValue),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onEdgeHandleStateChanged(edge),
        onPointerMove: (PointerMoveEvent event) => onDrag(event.delta),
        onPointerUp: (_) => onEdgeHandleStateChanged(null),
        onPointerCancel: (_) => onEdgeHandleStateChanged(null),
      ),
    );
  }

  Widget _buildCornerHandle({
    required String keyValue,
    required _TemplateGuideCorner corner,
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Listener(
        key: ValueKey<String>(keyValue),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onCornerHandleStateChanged(corner),
        onPointerMove: (PointerMoveEvent event) {
          onCornerHandleDrag(corner, event.delta);
        },
        onPointerUp: (_) => onCornerHandleStateChanged(null),
        onPointerCancel: (_) => onCornerHandleStateChanged(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double safeScaleX = scaleX.isFinite ? scaleX.clamp(0.2, 8) : 1;
    final double safeScaleY = scaleY.isFinite ? scaleY.clamp(0.2, 8) : 1;
    final double safeRotation = rotation.isFinite ? rotation : 0;
    final Offset panOffset = Offset(width * offsetX, height * offsetY);
    const double topEdge = 0;
    const double leftEdge = 0;
    final double rightEdge = width;
    final double bottomEdge = height;
    const double minTouchTarget = 44;
    final double edgeHitThicknessY = (minTouchTarget / safeScaleY)
        .clamp(26.0, 96.0)
        .toDouble();
    final double edgeHitThicknessX = (minTouchTarget / safeScaleX)
        .clamp(26.0, 96.0)
        .toDouble();
    final double cornerHitSize = math
        .max(minTouchTarget / safeScaleX, minTouchTarget / safeScaleY)
        .clamp(32.0, 110.0)
        .toDouble();
    final double edgeWidth = rightEdge - leftEdge;
    final double edgeHeight = bottomEdge - topEdge;

    return Transform.translate(
      offset: panOffset,
      child: Transform.rotate(
        angle: safeRotation,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            safeScaleX.toDouble(),
            safeScaleY.toDouble(),
            1,
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: 0,
                  width: width,
                  height: height,
                  child: CustomPaint(
                    painter: _TemplateAdjustGuidePainter(
                      activeCorner: activeCorner,
                      activeEdge: activeEdge,
                    ),
                  ),
                ),
                _buildEdgeHandle(
                  keyValue: 'template-adjust-edge-top',
                  edge: _TemplateGuideEdge.top,
                  left: leftEdge,
                  top: topEdge - (edgeHitThicknessY / 2),
                  width: edgeWidth,
                  height: edgeHitThicknessY,
                  onDrag: onTopHandleDrag,
                ),
                _buildEdgeHandle(
                  keyValue: 'template-adjust-edge-bottom',
                  edge: _TemplateGuideEdge.bottom,
                  left: leftEdge,
                  top: bottomEdge - (edgeHitThicknessY / 2),
                  width: edgeWidth,
                  height: edgeHitThicknessY,
                  onDrag: onBottomHandleDrag,
                ),
                _buildEdgeHandle(
                  keyValue: 'template-adjust-edge-left',
                  edge: _TemplateGuideEdge.left,
                  left: leftEdge - (edgeHitThicknessX / 2),
                  top: topEdge,
                  width: edgeHitThicknessX,
                  height: edgeHeight,
                  onDrag: onLeftHandleDrag,
                ),
                _buildEdgeHandle(
                  keyValue: 'template-adjust-edge-right',
                  edge: _TemplateGuideEdge.right,
                  left: rightEdge - (edgeHitThicknessX / 2),
                  top: topEdge,
                  width: edgeHitThicknessX,
                  height: edgeHeight,
                  onDrag: onRightHandleDrag,
                ),
                _buildCornerHandle(
                  keyValue: 'template-adjust-corner-top-left',
                  corner: _TemplateGuideCorner.topLeft,
                  left: -(cornerHitSize / 2),
                  top: -(cornerHitSize / 2),
                  size: cornerHitSize,
                ),
                _buildCornerHandle(
                  keyValue: 'template-adjust-corner-top-right',
                  corner: _TemplateGuideCorner.topRight,
                  left: rightEdge - (cornerHitSize / 2),
                  top: -(cornerHitSize / 2),
                  size: cornerHitSize,
                ),
                _buildCornerHandle(
                  keyValue: 'template-adjust-corner-bottom-left',
                  corner: _TemplateGuideCorner.bottomLeft,
                  left: -(cornerHitSize / 2),
                  top: bottomEdge - (cornerHitSize / 2),
                  size: cornerHitSize,
                ),
                _buildCornerHandle(
                  keyValue: 'template-adjust-corner-bottom-right',
                  corner: _TemplateGuideCorner.bottomRight,
                  left: rightEdge - (cornerHitSize / 2),
                  top: bottomEdge - (cornerHitSize / 2),
                  size: cornerHitSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateAdjustGuidePainter extends CustomPainter {
  const _TemplateAdjustGuidePainter({
    required this.activeCorner,
    required this.activeEdge,
  });

  final _TemplateGuideCorner? activeCorner;
  final _TemplateGuideEdge? activeEdge;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect borderRect = (Offset.zero & size).deflate(0.8);
    if (borderRect.width <= 0 || borderRect.height <= 0) return;
    final double minEdge = math.min(borderRect.width, borderRect.height);
    final RRect borderRRect = RRect.fromRectAndRadius(
      borderRect,
      Radius.circular((minEdge * 0.08).clamp(6.0, 12.0).toDouble()),
    );
    final Paint shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = AppColors.black.withValues(alpha: 0.26);
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.white;
    canvas.drawRRect(borderRRect, shadowPaint);
    canvas.drawRRect(borderRRect, strokePaint);

    final double handleRadius = (minEdge * 0.045).clamp(4.8, 7.2).toDouble();
    final double horizontalHandleWidth = (minEdge * 0.26)
        .clamp(22.0, 30.0)
        .toDouble();
    final double verticalHandleHeight = (minEdge * 0.26)
        .clamp(22.0, 30.0)
        .toDouble();
    final double handleThickness = (handleRadius * 1.7).clamp(8.0, 10.0);

    final Map<_TemplateGuideCorner, Offset> cornerPoints =
        <_TemplateGuideCorner, Offset>{
          _TemplateGuideCorner.topLeft: borderRect.topLeft,
          _TemplateGuideCorner.topRight: borderRect.topRight,
          _TemplateGuideCorner.bottomLeft: borderRect.bottomLeft,
          _TemplateGuideCorner.bottomRight: borderRect.bottomRight,
        };
    for (final MapEntry<_TemplateGuideCorner, Offset> entry
        in cornerPoints.entries) {
      _drawCircleHandle(
        canvas,
        center: entry.value,
        radius: handleRadius,
        isActive: entry.key == activeCorner,
      );
    }

    _drawPillHandle(
      canvas,
      center: Offset(borderRect.center.dx, borderRect.top),
      width: horizontalHandleWidth,
      height: handleThickness,
      isActive: activeEdge == _TemplateGuideEdge.top,
    );
    _drawPillHandle(
      canvas,
      center: Offset(borderRect.center.dx, borderRect.bottom),
      width: horizontalHandleWidth,
      height: handleThickness,
      isActive: activeEdge == _TemplateGuideEdge.bottom,
    );
    _drawPillHandle(
      canvas,
      center: Offset(borderRect.left, borderRect.center.dy),
      width: handleThickness,
      height: verticalHandleHeight,
      isActive: activeEdge == _TemplateGuideEdge.left,
    );
    _drawPillHandle(
      canvas,
      center: Offset(borderRect.right, borderRect.center.dy),
      width: handleThickness,
      height: verticalHandleHeight,
      isActive: activeEdge == _TemplateGuideEdge.right,
    );
  }

  void _drawCircleHandle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required bool isActive,
  }) {
    if (isActive) {
      canvas.drawCircle(
        center,
        radius + 1.6,
        Paint()..color = AppColors.black.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        center,
        radius + 0.4,
        Paint()..color = AppColors.colorF586AA6,
      );
      canvas.drawCircle(
        center,
        radius + 0.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.white,
      );
      return;
    }

    canvas.drawCircle(
      center,
      radius + 1.2,
      Paint()..color = AppColors.black.withValues(alpha: 0.24),
    );
    canvas.drawCircle(center, radius, Paint()..color = AppColors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.stampverseBorderSoft,
    );
  }

  void _drawPillHandle(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required bool isActive,
  }) {
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(math.min(width, height) / 2),
    );
    if (isActive) {
      canvas.drawRRect(
        rect.inflate(1.4),
        Paint()..color = AppColors.black.withValues(alpha: 0.28),
      );
      canvas.drawRRect(rect, Paint()..color = AppColors.colorF586AA6);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = AppColors.white,
      );
      return;
    }

    canvas.drawRRect(
      rect.inflate(1.2),
      Paint()..color = AppColors.black.withValues(alpha: 0.24),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.stampverseBorderSoft,
    );
  }

  @override
  bool shouldRepaint(covariant _TemplateAdjustGuidePainter oldDelegate) {
    return oldDelegate.activeCorner != activeCorner ||
        oldDelegate.activeEdge != activeEdge;
  }
}

class _TemplateSlotImageViewport extends StatelessWidget {
  const _TemplateSlotImageViewport({
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
                  child: _TemplateSlotImage(imageUrl: imageUrl),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TemplateSlotImage extends StatelessWidget {
  const _TemplateSlotImage({required this.imageUrl});

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

class _EditBoardChip extends StatelessWidget {
  const _EditBoardChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? AppColors.colorF586AA6.withValues(alpha: 0.16)
                : AppColors.white.withValues(alpha: 0.78),
            border: Border.all(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampverseBorderSoft,
            ),
          ),
          child: Text(
            title,
            style: StampverseTextStyles.caption(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampversePrimaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFilterChip extends StatelessWidget {
  const _EditFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? AppColors.colorF586AA6.withValues(alpha: 0.18)
                : AppColors.white,
            border: Border.all(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampverseBorderSoft,
            ),
          ),
          child: Text(
            label,
            style: StampverseTextStyles.caption(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampversePrimaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditTrashDropZone extends StatelessWidget {
  const _EditTrashDropZone({super.key, required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlighted
            ? AppColors.stampverseDanger.withValues(alpha: 0.14)
            : AppColors.white.withValues(alpha: 0.76),
        border: Border.all(
          color: highlighted
              ? AppColors.stampverseDanger
              : AppColors.stampverseBorderSoft,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: highlighted
                ? AppColors.stampverseDanger
                : AppColors.stampverseMutedText,
          ),
          const SizedBox(width: 8),
          Text(
            LocaleKey.stampverseEditTrashLabel.tr,
            style: StampverseTextStyles.caption(
              color: highlighted
                  ? AppColors.stampverseDanger
                  : AppColors.stampverseMutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
