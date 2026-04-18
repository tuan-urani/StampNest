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
  static const double _kTemplateToolbarWidth = 156;
  static const double _kTemplateToolbarHeight = 44;
  static const double _kTemplateToolbarGap = 10;
  static const double _kTemplateToolbarCanvasPadding = 8;

  StampEditBoard? _workingBoard;
  String? _selectedLayerId;
  _LayerGestureSession? _gestureSession;
  final GlobalKey _trashZoneKey = GlobalKey();
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  bool _isTrashHovering = false;

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
    final BuildContext? boundaryContext = _canvasBoundaryKey.currentContext;
    if (boundaryContext == null) return null;
    final RenderObject? renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final RenderRepaintBoundary boundary = renderObject;

    try {
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
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
                showAddAction: !_layerHasImage(layer),
                isSelected: isSelected,
                isLocked: layer.isLocked,
                frameShape: layer.frameShape,
                enableAssetFrameOverlay: widget.enableAssetFrameOverlay,
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
                              borderRadius: BorderRadius.circular(18),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: canvasColor,
                                  border: Border.all(
                                    color: AppColors.stampverseBorderSoft,
                                  ),
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

class _TemplateSlotToolbar extends StatelessWidget {
  const _TemplateSlotToolbar({
    required this.isLocked,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleLock,
  });

  final bool isLocked;
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
  });

  final double width;
  final double height;
  final String imageUrl;
  final bool showAddAction;
  final bool isSelected;
  final bool isLocked;
  final StampEditFrameShape frameShape;
  final bool enableAssetFrameOverlay;

  String? _frameOverlayAssetPath() {
    if (!enableAssetFrameOverlay) return null;
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
    final Color slotBackgroundColor = AppColors.stampverseBorderSoft.withValues(
      alpha: 0.36,
    );
    final double borderWidth = isSelected ? 2 : 1.2;
    final Color borderColor = isSelected
        ? AppColors.colorF586AA6
        : frameShape == StampEditFrameShape.stampClassic
        ? AppColors.stampversePrimaryText
        : AppColors.white;
    final String? overlayAssetPath = _frameOverlayAssetPath();
    final bool showPainterBorder = overlayAssetPath == null;

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, constraints.maxHeight);
          final Rect frameRect = Offset.zero & size;
          final bool isClassicStamp =
              frameShape == StampEditFrameShape.stampClassic;
          final double innerInset = (math.min(width, height) * 0.16)
              .clamp(5.0, 16.0)
              .toDouble();

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (isClassicStamp)
                _buildTemplateFrameClip(
                  frameShape: frameShape,
                  clipRect: frameRect,
                  child: const ColoredBox(color: AppColors.colorF8F1DD),
                )
              else
                _buildTemplateFrameClip(
                  frameShape: frameShape,
                  clipRect: frameRect,
                  child: ColoredBox(
                    color: slotBackgroundColor,
                    child: imageUrl.trim().isEmpty
                        ? null
                        : _TemplateSlotImage(imageUrl: imageUrl),
                  ),
                ),
              if (isClassicStamp)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(innerInset),
                    child: ColoredBox(
                      color: slotBackgroundColor,
                      child: imageUrl.trim().isEmpty
                          ? null
                          : _TemplateSlotImage(imageUrl: imageUrl),
                    ),
                  ),
                ),
              CustomPaint(
                painter: showPainterBorder
                    ? _TemplateSlotBorderPainter(
                        frameShape: frameShape,
                        borderColor: borderColor,
                        borderWidth: borderWidth,
                      )
                    : null,
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
              if (isLocked)
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
  required Widget child,
}) {
  switch (frameShape) {
    case StampEditFrameShape.plainCircle:
      return ClipOval(child: child);
    case StampEditFrameShape.plainRect:
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
    case StampEditFrameShape.stampScallop:
    case StampEditFrameShape.stampCircle:
    case StampEditFrameShape.stampSquare:
    case StampEditFrameShape.stampClassic:
      return ClipPath(
        clipper: _TemplateSlotFrameClipper(
          frameShape: frameShape,
          clipRect: clipRect,
        ),
        child: child,
      );
  }
}

Path _buildTemplateFramePath({
  required StampEditFrameShape frameShape,
  required Rect rect,
}) {
  return buildTemplateFramePath(frameShape: frameShape, rect: rect);
}

class _TemplateSlotFrameClipper extends CustomClipper<Path> {
  const _TemplateSlotFrameClipper({
    required this.frameShape,
    required this.clipRect,
  });

  final StampEditFrameShape frameShape;
  final Rect clipRect;

  @override
  Path getClip(Size size) {
    return _buildTemplateFramePath(frameShape: frameShape, rect: clipRect);
  }

  @override
  bool shouldReclip(covariant _TemplateSlotFrameClipper oldClipper) {
    return oldClipper.frameShape != frameShape ||
        oldClipper.clipRect != clipRect;
  }
}

class _TemplateSlotBorderPainter extends CustomPainter {
  const _TemplateSlotBorderPainter({
    required this.frameShape,
    required this.borderColor,
    required this.borderWidth,
  });

  final StampEditFrameShape frameShape;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect borderRect = (Offset.zero & size).deflate(borderWidth / 2);
    final Path borderPath = _buildTemplateFramePath(
      frameShape: frameShape,
      rect: borderRect,
    );
    final bool isClassicStamp = frameShape == StampEditFrameShape.stampClassic;
    canvas.drawPath(
      borderPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isClassicStamp
            ? math.max(1.8, borderWidth + 0.5)
            : borderWidth
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TemplateSlotBorderPainter oldDelegate) {
    return oldDelegate.frameShape != frameShape ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
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
            fit: BoxFit.cover,
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
