import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/locale/translation_manager.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_add_stamp_fab.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse/interactor/stampverse_state.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_shared.dart';

class StampverseCollectionSummary {
  const StampverseCollectionSummary({required this.name, required this.stamps});

  final String name;
  final List<StampDataModel> stamps;

  DateTime get latestDate {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final StampDataModel item in stamps) {
      final DateTime candidate = item.parsedDate ?? latest;
      if (candidate.isAfter(latest)) {
        latest = candidate;
      }
    }
    return latest;
  }
}

class StampverseHomeView extends StatelessWidget {
  const StampverseHomeView({
    super.key,
    required this.tab,
    required this.lastMainHomeTab,
    required this.stamps,
    required this.collections,
    required this.editBoards,
    required this.selectedEditBoardIds,
    required this.onTabChanged,
    required this.onOpenCollection,
    required this.onOpenCreateEditBoard,
    required this.onOpenEditBoard,
    required this.onStartEditBoardSelection,
    required this.onToggleEditBoardSelection,
    required this.onClearEditBoardSelection,
    required this.onDeleteSelectedEditBoards,
    required this.onAddFromCamera,
    required this.onAddFromFile,
    required this.onSelectStamp,
    required this.onRefresh,
    required this.onLogout,
    required this.onOpenPrivacyPolicy,
    required this.onOpenTermsOfUse,
    this.isRefreshing = false,
  });

  final StampverseHomeTab tab;
  final StampverseHomeTab lastMainHomeTab;
  final List<StampDataModel> stamps;
  final List<StampverseCollectionSummary> collections;
  final List<StampEditBoard> editBoards;
  final List<String> selectedEditBoardIds;
  final ValueChanged<StampverseHomeTab> onTabChanged;
  final ValueChanged<String> onOpenCollection;
  final VoidCallback onOpenCreateEditBoard;
  final ValueChanged<String> onOpenEditBoard;
  final ValueChanged<String> onStartEditBoardSelection;
  final ValueChanged<String> onToggleEditBoardSelection;
  final VoidCallback onClearEditBoardSelection;
  final VoidCallback onDeleteSelectedEditBoards;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFromFile;
  final ValueChanged<String> onSelectStamp;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenTermsOfUse;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final StampverseHomeTab settingsBackTab = _resolveLastMainTab();
    final StampverseHomeTab bottomBarActiveTab =
        tab == StampverseHomeTab.settings ? settingsBackTab : tab;
    final bool isEditSelectionMode =
        tab == StampverseHomeTab.edit && selectedEditBoardIds.isNotEmpty;

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                  child: Row(
                    children: <Widget>[
                      if (tab == StampverseHomeTab.settings ||
                          isEditSelectionMode) ...<Widget>[
                        _TopRoundActionButton(
                          icon: tab == StampverseHomeTab.settings
                              ? Icons.arrow_back_rounded
                              : Icons.close_rounded,
                          onTap: tab == StampverseHomeTab.settings
                              ? () => onTabChanged(settingsBackTab)
                              : onClearEditBoardSelection,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          _titleOfTab(tab),
                          style: StampverseTextStyles.sectionTitle(
                            color: AppColors.stampverseHeadingText,
                          ),
                        ),
                      ),
                      if (isEditSelectionMode)
                        _TopRoundActionButton(
                          icon: Icons.delete_outline_rounded,
                          iconColor: AppColors.stampverseDanger,
                          onTap: onDeleteSelectedEditBoards,
                        )
                      else if (_isMainHomeTab(tab))
                        _TopRoundActionButton(
                          icon: Icons.settings_rounded,
                          onTap: () => onTabChanged(StampverseHomeTab.settings),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey<StampverseHomeTab>(tab),
                      child: _buildTabContent(),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _HomeBottomTabBar(
                activeTab: bottomBarActiveTab,
                onChanged: onTabChanged,
              ),
            ),
            if (tab != StampverseHomeTab.edit &&
                tab != StampverseHomeTab.settings)
              Positioned(
                right: 26,
                bottom: 114,
                child: StampverseAddStampFab(
                  onOpenCamera: onAddFromCamera,
                  onOpenGallery: onAddFromFile,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _titleOfTab(StampverseHomeTab currentTab) {
    switch (currentTab) {
      case StampverseHomeTab.stamp:
        return LocaleKey.stampverseHomeTabStamp.tr;
      case StampverseHomeTab.collection:
        return LocaleKey.stampverseHomeTabCollection.tr;
      case StampverseHomeTab.memory:
        return LocaleKey.stampverseHomeTabMemory.tr;
      case StampverseHomeTab.edit:
        return LocaleKey.stampverseHomeTabEdit.tr;
      case StampverseHomeTab.settings:
        return LocaleKey.stampverseHomeTabSettings.tr;
    }
  }

  Widget _buildTabContent() {
    switch (tab) {
      case StampverseHomeTab.stamp:
        return _StampTab(stamps: stamps, onSelectStamp: onSelectStamp);
      case StampverseHomeTab.collection:
        return _CollectionTab(
          collections: collections,
          onOpenCollection: onOpenCollection,
          onSelectStamp: onSelectStamp,
        );
      case StampverseHomeTab.memory:
        return _MemoryTimelineTab(stamps: stamps, onSelectStamp: onSelectStamp);
      case StampverseHomeTab.edit:
        return _EditBoardsTab(
          boards: editBoards,
          selectedBoardIds: selectedEditBoardIds,
          onCreateBoard: onOpenCreateEditBoard,
          onOpenBoard: onOpenEditBoard,
          onStartSelection: onStartEditBoardSelection,
          onToggleSelection: onToggleEditBoardSelection,
        );
      case StampverseHomeTab.settings:
        return _SettingsTab(
          stampsCount: stamps.length,
          collectionsCount: collections.length,
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
          onResetLocal: onLogout,
          onOpenPrivacyPolicy: onOpenPrivacyPolicy,
          onOpenTermsOfUse: onOpenTermsOfUse,
        );
    }
  }

  bool _isMainHomeTab(StampverseHomeTab value) {
    switch (value) {
      case StampverseHomeTab.stamp:
      case StampverseHomeTab.collection:
      case StampverseHomeTab.memory:
      case StampverseHomeTab.edit:
        return true;
      case StampverseHomeTab.settings:
        return false;
    }
  }

  StampverseHomeTab _resolveLastMainTab() {
    if (_isMainHomeTab(lastMainHomeTab)) {
      return lastMainHomeTab;
    }
    return StampverseHomeTab.stamp;
  }
}

class _StampTab extends StatelessWidget {
  const _StampTab({required this.stamps, required this.onSelectStamp});

  final List<StampDataModel> stamps;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return _EmptyTab(
        icon: Icons.auto_awesome_mosaic_rounded,
        title: LocaleKey.stampverseHomeEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeEmptySubtitle.tr,
      );
    }

    final List<StampDataModel> recentOpened = _resolveRecentOpened(stamps);
    final List<StampDataModel> favorites = _resolveFavorites(stamps);

    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final int crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        final double contentWidth = (constraints.maxWidth - 48).clamp(
          0,
          double.infinity,
        );
        final double stampTileWidth =
            (contentWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;
        final double recentRowHeight = (stampTileWidth / 0.75) + 32;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
          children: <Widget>[
            _StampSectionHeader(title: LocaleKey.stampverseHomeStampRecent.tr),
            const SizedBox(height: 10),
            if (recentOpened.isEmpty)
              _SectionEmptyText(
                text: LocaleKey.stampverseHomeStampRecentEmpty.tr,
              )
            else
              SizedBox(
                height: recentRowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentOpened.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, int index) {
                    final StampDataModel item = recentOpened[index];
                    final DateTime openedAt =
                        item.parsedLastOpenedAt ??
                        item.parsedDate ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                    return SizedBox(
                      width: stampTileWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StampverseStamp(
                            imageUrl: item.imageUrl,
                            shapeType: item.shapeType,
                            width: stampTileWidth,
                            onTap: () => onSelectStamp(item.id),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              DateFormat('HH:mm').format(openedAt),
                              style: StampverseTextStyles.caption(
                                color: AppColors.stampverseMutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Divider(
              color: AppColors.stampverseBorderSoft.withValues(alpha: 0.9),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
            _StampSectionHeader(
              title: LocaleKey.stampverseHomeStampFavorite.tr,
            ),
            const SizedBox(height: 10),
            if (favorites.isEmpty)
              _SectionEmptyText(
                text: LocaleKey.stampverseHomeStampFavoriteEmpty.tr,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: favorites.length,
                itemBuilder: (_, int index) {
                  final StampDataModel item = favorites[index];
                  return StampverseStamp(
                    imageUrl: item.imageUrl,
                    shapeType: item.shapeType,
                    onTap: () => onSelectStamp(item.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  List<StampDataModel> _resolveRecentOpened(List<StampDataModel> source) {
    final List<StampDataModel> items = source
        .where((StampDataModel stamp) => stamp.parsedLastOpenedAt != null)
        .toList(growable: false);

    items.sort((StampDataModel a, StampDataModel b) {
      final DateTime dateA =
          a.parsedLastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB =
          b.parsedLastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return items.take(12).toList(growable: false);
  }

  List<StampDataModel> _resolveFavorites(List<StampDataModel> source) {
    final List<StampDataModel> items = source
        .where((StampDataModel stamp) => stamp.isFavorite)
        .toList(growable: false);

    items.sort((StampDataModel a, StampDataModel b) {
      final DateTime dateA =
          a.parsedLastOpenedAt ??
          a.parsedDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB =
          b.parsedLastOpenedAt ??
          b.parsedDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return items;
  }
}

class _StampSectionHeader extends StatelessWidget {
  const _StampSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: StampverseTextStyles.body(
        color: AppColors.stampverseHeadingText,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SectionEmptyText extends StatelessWidget {
  const _SectionEmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: StampverseTextStyles.caption(color: AppColors.stampverseMutedText),
    );
  }
}

class _CollectionTab extends StatelessWidget {
  const _CollectionTab({
    required this.collections,
    required this.onOpenCollection,
    required this.onSelectStamp,
  });

  final List<StampverseCollectionSummary> collections;
  final ValueChanged<String> onOpenCollection;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return _EmptyTab(
        icon: Icons.collections_bookmark_outlined,
        title: LocaleKey.stampverseHomeCollectionEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeCollectionEmptySubtitle.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
      itemCount: collections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, int index) {
        final StampverseCollectionSummary summary = collections[index];
        final List<StampDataModel> previewItems = summary.stamps
            .take(4)
            .toList(growable: false);

        return Material(
          color: AppColors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpenCollection(summary.name),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stampverseBorderSoft),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            summary.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StampverseTextStyles.body(
                              color: AppColors.stampverseHeadingText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          LocaleKey.stampverseHomeStampsCount.trParams(
                            <String, String>{
                              'count': '${summary.stamps.length}',
                            },
                          ),
                          style: StampverseTextStyles.caption(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: previewItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, int itemIndex) {
                          final StampDataModel preview =
                              previewItems[itemIndex];
                          return StampverseStamp(
                            imageUrl: preview.imageUrl,
                            shapeType: preview.shapeType,
                            width: 70,
                            onTap: () => onSelectStamp(preview.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditBoardsTab extends StatelessWidget {
  const _EditBoardsTab({
    required this.boards,
    required this.selectedBoardIds,
    required this.onCreateBoard,
    required this.onOpenBoard,
    required this.onStartSelection,
    required this.onToggleSelection,
  });

  final List<StampEditBoard> boards;
  final List<String> selectedBoardIds;
  final VoidCallback onCreateBoard;
  final ValueChanged<String> onOpenBoard;
  final ValueChanged<String> onStartSelection;
  final ValueChanged<String> onToggleSelection;

  @override
  Widget build(BuildContext context) {
    if (boards.isEmpty) {
      return _EmptyTab(
        icon: Icons.edit_note_rounded,
        title: LocaleKey.stampverseHomeEditEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeCollectionEmptySubtitle.tr,
        actionLabel: LocaleKey.stampverseHomeEditEmptyAction.tr,
        onActionTap: onCreateBoard,
      );
    }

    final Set<String> selectedSet = selectedBoardIds.toSet();
    final bool isSelectionMode = selectedSet.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
      children: <Widget>[
        if (!isSelectionMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCreateBoard,
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
          final StampEditLayer? previewLayer = board.layers.isEmpty
              ? null
              : board.layers.last;
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
                          child: previewLayer == null
                              ? DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.stampverseSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.stampverseBorderSoft,
                                    ),
                                  ),
                                  child: const AspectRatio(
                                    aspectRatio: 1,
                                    child: Icon(
                                      Icons.photo_library_outlined,
                                      color: AppColors.stampverseMutedText,
                                    ),
                                  ),
                                )
                              : StampverseStamp(
                                  imageUrl: previewLayer.imageUrl,
                                  shapeType: previewLayer.shapeType,
                                  width: 70,
                                ),
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
      return _EmptyTab(
        icon: Icons.edit_note_rounded,
        title: LocaleKey.stampverseHomeEditEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeCollectionEmptySubtitle.tr,
        actionLabel: LocaleKey.stampverseHomeEditEmptyAction.tr,
        onActionTap: widget.onCreateBoard,
      );
    }

    final EdgeInsets contentPadding = widget.showBoardHeader
        ? const EdgeInsets.fromLTRB(16, 0, 16, 160)
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

class _MemoryTimelineTab extends StatelessWidget {
  const _MemoryTimelineTab({required this.stamps, required this.onSelectStamp});

  final List<StampDataModel> stamps;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return _EmptyTab(
        icon: Icons.schedule_outlined,
        title: LocaleKey.stampverseHomeMemoryEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeMemoryEmptySubtitle.tr,
      );
    }
    final Map<DateTime, List<StampDataModel>> groupedByDay = _groupByDay(
      stamps,
    );
    final DateTime today = _normalizeDay(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stampverseBorderSoft),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.stampverseShadowCard,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SfCalendar(
            view: CalendarView.month,
            firstDayOfWeek: DateTime.monday,
            showDatePickerButton: true,
            headerHeight: 46,
            viewHeaderHeight: 28,
            cellBorderColor: AppColors.transparent,
            backgroundColor: AppColors.transparent,
            todayHighlightColor: AppColors.colorEF4056,
            headerStyle: CalendarHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: StampverseTextStyles.body(
                color: AppColors.stampverseHeadingText,
                fontWeight: FontWeight.w700,
              ),
            ),
            viewHeaderStyle: ViewHeaderStyle(
              dayTextStyle: StampverseTextStyles.caption(
                color: AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.none,
              showTrailingAndLeadingDates: false,
            ),
            monthCellBuilder: (_, MonthCellDetails details) {
              final DateTime day = _normalizeDay(details.date);
              final List<StampDataModel> dayStamps =
                  groupedByDay[day] ?? const <StampDataModel>[];
              final StampDataModel? firstStamp = dayStamps.isEmpty
                  ? null
                  : dayStamps.first;

              return _MemoryCalendarCell(
                day: day,
                firstStamp: firstStamp,
                isToday: day == today,
                isSunday: day.weekday == DateTime.sunday,
              );
            },
            onTap: (CalendarTapDetails details) {
              final DateTime? tappedDate = details.date;
              if (tappedDate == null) return;

              final DateTime day = _normalizeDay(tappedDate);
              final List<StampDataModel> dayStamps =
                  groupedByDay[day] ?? const <StampDataModel>[];
              if (dayStamps.isEmpty) return;

              _showDayStampsSheet(
                context: context,
                day: day,
                dayStamps: dayStamps,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDayStampsSheet({
    required BuildContext context,
    required DateTime day,
    required List<StampDataModel> dayStamps,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _MemoryDayStampsSheet(
          day: day,
          dayStamps: dayStamps,
          onSelectStamp: onSelectStamp,
        );
      },
    );
  }

  Map<DateTime, List<StampDataModel>> _groupByDay(List<StampDataModel> source) {
    final Map<DateTime, List<StampDataModel>> grouped =
        <DateTime, List<StampDataModel>>{};

    for (final StampDataModel stamp in source) {
      final DateTime date =
          stamp.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime day = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => <StampDataModel>[]).add(stamp);
    }

    for (final List<StampDataModel> dayStamps in grouped.values) {
      dayStamps.sort((StampDataModel a, StampDataModel b) {
        final DateTime dateA =
            a.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
    }

    return grouped;
  }

  DateTime _normalizeDay(DateTime date) {
    final DateTime local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class _MemoryCalendarCell extends StatelessWidget {
  const _MemoryCalendarCell({
    required this.day,
    required this.firstStamp,
    required this.isToday,
    required this.isSunday,
  });

  final DateTime day;
  final StampDataModel? firstStamp;
  final bool isToday;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    final Color dayColor = isToday
        ? AppColors.stampverseDanger
        : (isSunday
              ? AppColors.stampverseDanger.withValues(alpha: 0.78)
              : AppColors.stampversePrimaryText);

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stampverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? AppColors.stampverseDanger.withValues(alpha: 0.36)
                : AppColors.stampverseBorderSoft,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 6,
              left: 6,
              child: Text(
                '${day.day}',
                style: StampverseTextStyles.caption(
                  color: dayColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (firstStamp != null)
              Positioned.fill(
                top: 0,
                left: 4,
                right: 4,
                bottom: 4,
                child: LayoutBuilder(
                  builder: (_, BoxConstraints constraints) {
                    final double maxWidth = constraints.maxWidth;
                    final double maxHeight = constraints.maxHeight;
                    final StampShapeType shapeType = firstStamp!.shapeType;
                    final double widthByHeight =
                        maxHeight * shapeType.aspectRatio;
                    final double stampWidth = widthByHeight < maxWidth
                        ? widthByHeight
                        : maxWidth;

                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: StampverseStamp(
                        imageUrl: firstStamp!.imageUrl,
                        shapeType: shapeType,
                        width: stampWidth,
                        showShadow: false,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDayStampsSheet extends StatelessWidget {
  const _MemoryDayStampsSheet({
    required this.day,
    required this.dayStamps,
    required this.onSelectStamp,
  });

  final DateTime day;
  final List<StampDataModel> dayStamps;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    final List<StampDataModel> sorted = List<StampDataModel>.from(dayStamps)
      ..sort((StampDataModel a, StampDataModel b) {
        final DateTime dateA =
            a.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.parsedDate?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stampverseBorderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM y').format(day),
                      style: StampverseTextStyles.body(
                        color: AppColors.stampverseHeadingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.stampversePrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, int index) {
                  final StampDataModel stamp = sorted[index];
                  final DateTime time =
                      stamp.parsedDate?.toLocal() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final String collectionName = _resolveCollectionName(stamp);

                  return Material(
                    color: AppColors.stampverseBackground,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectStamp(stamp.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: <Widget>[
                            StampverseStamp(
                              imageUrl: stamp.imageUrl,
                              shapeType: stamp.shapeType,
                              width: 70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    stamp.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StampverseTextStyles.body(
                                      color: AppColors.stampverseHeadingText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(time),
                                    style: StampverseTextStyles.caption(
                                      color: AppColors.stampverseMutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    collectionName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StampverseTextStyles.caption(
                                      color: AppColors.stampversePrimaryText,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  String _resolveCollectionName(StampDataModel stamp) {
    final String album = stamp.album?.trim() ?? '';
    if (album.isNotEmpty) {
      return album;
    }
    return LocaleKey.stampverseHomeMemoryNoCollection.tr;
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.stampsCount,
    required this.collectionsCount,
    required this.onRefresh,
    required this.onResetLocal,
    required this.onOpenPrivacyPolicy,
    required this.onOpenTermsOfUse,
    this.isRefreshing = false,
  });

  final int stampsCount;
  final int collectionsCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onResetLocal;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenTermsOfUse;

  static const List<_SettingsLanguageOption> _languageOptions =
      <_SettingsLanguageOption>[
        _SettingsLanguageOption(
          languageCode: 'vi',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageVietnamese,
        ),
        _SettingsLanguageOption(
          languageCode: 'en',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageEnglish,
        ),
        _SettingsLanguageOption(
          languageCode: 'ja',
          labelKey: LocaleKey.stampverseHomeSettingsLanguageJapanese,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final String selectedLanguageCode = _resolveSelectedLanguageCode();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
      child: Column(
        children: <Widget>[
          _SettingsLanguageCard(
            label: LocaleKey.stampverseHomeSettingsLanguage.tr,
            selectedLanguageCode: selectedLanguageCode,
            options: _languageOptions,
            onChanged: _onLanguageChanged,
          ),
          const SizedBox(height: 12),
          _SettingsMenuButton(
            icon: Icons.privacy_tip_outlined,
            label: LocaleKey.stampverseHomeSettingsPrivacyPolicy.tr,
            onTap: onOpenPrivacyPolicy,
          ),
          const SizedBox(height: 10),
          _SettingsMenuButton(
            icon: Icons.description_outlined,
            label: LocaleKey.stampverseHomeSettingsTermsOfUse.tr,
            onTap: onOpenTermsOfUse,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            stampsCount: stampsCount,
            collectionsCount: collectionsCount,
          ),
          const SizedBox(height: 12),
          _SettingsActionButton(
            icon: Icons.refresh_rounded,
            label: LocaleKey.stampverseHomeSettingsRefresh.tr,
            onTap: onRefresh,
            loading: isRefreshing,
          ),
          const SizedBox(height: 10),
          _SettingsActionButton(
            icon: Icons.delete_forever_rounded,
            label: LocaleKey.stampverseHomeSettingsResetLocal.tr,
            onTap: onResetLocal,
            danger: true,
          ),
        ],
      ),
    );
  }

  String _resolveSelectedLanguageCode() {
    final String currentLanguageCode =
        Get.locale?.languageCode ??
        TranslationManager.defaultLocale.languageCode;
    for (final _SettingsLanguageOption option in _languageOptions) {
      if (option.languageCode == currentLanguageCode) {
        return currentLanguageCode;
      }
    }
    return TranslationManager.defaultLocale.languageCode;
  }

  Future<void> _onLanguageChanged(String? languageCode) async {
    if (languageCode == null || languageCode.isEmpty) return;
    final Locale targetLocale =
        TranslationManager.resolveLocaleFromLanguageCode(languageCode);

    await Get.find<AppShared>().setLanguageCode(languageCode);
    await Get.updateLocale(targetLocale);
  }
}

class _SettingsLanguageOption {
  const _SettingsLanguageOption({
    required this.languageCode,
    required this.labelKey,
  });

  final String languageCode;
  final String labelKey;
}

class _SettingsLanguageCard extends StatelessWidget {
  const _SettingsLanguageCard({
    required this.label,
    required this.selectedLanguageCode,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String selectedLanguageCode;
  final List<_SettingsLanguageOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stampverseBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.language_rounded,
            size: 18,
            color: AppColors.stampversePrimaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: StampverseTextStyles.body(
                color: AppColors.stampversePrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguageCode,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: AppColors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.stampverseMutedText,
              ),
              style: StampverseTextStyles.caption(
                color: AppColors.stampverseHeadingText,
                fontWeight: FontWeight.w700,
              ),
              items: options
                  .map(
                    (_SettingsLanguageOption option) =>
                        DropdownMenuItem<String>(
                          value: option.languageCode,
                          child: Text(option.labelKey.tr),
                        ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stampverseBorderSoft),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 14),
                Icon(icon, size: 18, color: AppColors.stampversePrimaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: StampverseTextStyles.body(
                      color: AppColors.stampversePrimaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.stampverseMutedText,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomTabBar extends StatelessWidget {
  const _HomeBottomTabBar({required this.activeTab, required this.onChanged});

  final StampverseHomeTab activeTab;
  final ValueChanged<StampverseHomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.stampverseBorderSoft),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.stampverseShadowStrong,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: <Widget>[
            _HomeTabButton(
              tab: StampverseHomeTab.stamp,
              activeTab: activeTab,
              icon: Icons.style_outlined,
              label: LocaleKey.stampverseHomeTabStamp.tr,
              onChanged: onChanged,
            ),
            _HomeTabButton(
              tab: StampverseHomeTab.collection,
              activeTab: activeTab,
              icon: Icons.collections_bookmark_outlined,
              label: LocaleKey.stampverseHomeTabCollection.tr,
              onChanged: onChanged,
            ),
            _HomeTabButton(
              tab: StampverseHomeTab.edit,
              activeTab: activeTab,
              icon: Icons.edit_rounded,
              label: LocaleKey.stampverseHomeTabEdit.tr,
              onChanged: onChanged,
            ),
            _HomeTabButton(
              tab: StampverseHomeTab.memory,
              activeTab: activeTab,
              icon: Icons.history_rounded,
              label: LocaleKey.stampverseHomeTabMemory.tr,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabButton extends StatelessWidget {
  const _HomeTabButton({
    required this.tab,
    required this.activeTab,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  final StampverseHomeTab tab;
  final StampverseHomeTab activeTab;
  final IconData icon;
  final String label;
  final ValueChanged<StampverseHomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isActive = tab == activeTab;
    final Color foreground = isActive
        ? AppColors.stampverseHeadingText
        : AppColors.stampversePrimaryText;

    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
          focusColor: AppColors.transparent,
          hoverColor: AppColors.transparent,
          onTap: () => onChanged(tab),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isActive ? AppColors.stampverseBorderSoft : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StampverseTextStyles.caption(
                    color: foreground,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
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

class _TopRoundActionButton extends StatelessWidget {
  const _TopRoundActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.stampversePrimaryText,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final String? actionText = actionLabel;
    final VoidCallback? actionHandler = onActionTap;
    final bool hasAction =
        actionText != null &&
        actionText.trim().isNotEmpty &&
        actionHandler != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.stampverseSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: AppColors.stampverseMutedText),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: StampverseTextStyles.heroTitle(
                color: AppColors.stampverseMutedText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: StampverseTextStyles.body(),
            ),
            if (hasAction) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: Material(
                  color: AppColors.colorF586AA6,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: actionHandler,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text(
                          actionText,
                          style: StampverseTextStyles.body(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stampsCount, required this.collectionsCount});

  final int stampsCount;
  final int collectionsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stampverseBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatItem(
              label: LocaleKey.stampverseHomeSettingsTotalStamps.tr,
              value: '$stampsCount',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.stampverseBorderSoft,
          ),
          Expanded(
            child: _StatItem(
              label: LocaleKey.stampverseHomeSettingsTotalCollections.tr,
              value: '$collectionsCount',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: StampverseTextStyles.heroTitle(
            color: AppColors.stampverseHeadingText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: StampverseTextStyles.caption(),
        ),
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color foreground = danger
        ? AppColors.stampverseDanger
        : AppColors.stampversePrimaryText;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stampverseBorderSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: StampverseTextStyles.body(
                    color: foreground,
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
