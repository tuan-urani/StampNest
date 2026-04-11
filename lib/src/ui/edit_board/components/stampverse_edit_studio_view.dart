import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

enum _ImportStampSource { collection, daily }

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
  });

  final List<StampEditBoard> boards;
  final String? activeBoardId;
  final List<StampDataModel> stamps;
  final VoidCallback? onCreateBoard;
  final ValueChanged<String>? onSelectBoard;
  final ValueChanged<StampEditBoard> onSaveBoard;
  final StampverseEditStudioController? controller;
  final bool showBoardHeader;

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
    _gestureSession = _LayerGestureSession(
      layerId: layer.id,
      initialFocalPoint: details.focalPoint,
      initialCenterX: layer.centerX,
      initialCenterY: layer.centerY,
      initialScale: layer.scale,
      initialRotation: layer.rotation,
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

  String _dayKey(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _openImportSheet() async {
    if (_workingBoard == null) return;

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

  @override
  Widget build(BuildContext context) {
    final StampEditBoard? board = _workingBoard;
    if (board == null) {
      return StampverseEmptyTab(
        icon: Icons.edit_note_rounded,
        title: LocaleKey.stampverseHomeEditEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeCollectionEmptySubtitle.tr,
        actionLabel: LocaleKey.stampverseHomeEditEmptyAction.tr,
        onActionTap: widget.onCreateBoard,
      );
    }

    final EdgeInsets contentPadding = widget.showBoardHeader
        ? const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            StampverseLayout.contentBottomPadding,
          )
        : const EdgeInsets.fromLTRB(8, 0, 8, 8);

    return Padding(
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
            const SizedBox(height: 12),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (_, BoxConstraints constraints) {
                final Size canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return RepaintBoundary(
                  key: _canvasBoundaryKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(
                          color: AppColors.stampverseBorderSoft,
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: const _NotebookGridPainter(),
                            ),
                          ),
                          ...board.layers.map((StampEditLayer layer) {
                            final double baseHeight =
                                _kEditLayerBaseWidth /
                                layer.shapeType.aspectRatio;
                            final double scaledWidth =
                                _kEditLayerBaseWidth * layer.scale;
                            final double scaledHeight =
                                baseHeight * layer.scale;
                            final double gestureWidth =
                                scaledWidth + (_kEditLayerGesturePadding * 2);
                            final double gestureHeight =
                                scaledHeight + (_kEditLayerGesturePadding * 2);
                            final double left =
                                (layer.centerX * canvasSize.width) -
                                (gestureWidth / 2);
                            final double top =
                                (layer.centerY * canvasSize.height) -
                                (gestureHeight / 2);

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
                                    _onLayerScaleStart(
                                      layer,
                                      details,
                                      canvasSize,
                                    );
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
                          }),
                        ],
                      ),
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
          const SizedBox(height: 6),
          _EditTrashDropZone(key: _trashZoneKey, highlighted: _isTrashHovering),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _LayerGestureSession {
  _LayerGestureSession({
    required this.layerId,
    required this.initialFocalPoint,
    required this.initialCenterX,
    required this.initialCenterY,
    required this.initialScale,
    required this.initialRotation,
    required this.canvasSize,
    required this.currentFocalPoint,
  });

  final String layerId;
  final Offset initialFocalPoint;
  final double initialCenterX;
  final double initialCenterY;
  final double initialScale;
  final double initialRotation;
  final Size canvasSize;
  Offset currentFocalPoint;
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

class _NotebookGridPainter extends CustomPainter {
  const _NotebookGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 24;
    const double majorStep = 5;
    final Paint minor = Paint()
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.65)
      ..strokeWidth = 0.7;
    final Paint major = Paint()
      ..color = AppColors.stampverseBorderSoft.withValues(alpha: 0.95)
      ..strokeWidth = 1;

    int line = 0;
    for (double x = 0; x <= size.width; x += gridSize, line++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        line % majorStep == 0 ? major : minor,
      );
    }

    line = 0;
    for (double y = 0; y <= size.height; y += gridSize, line++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line % majorStep == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
