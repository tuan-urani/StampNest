import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampTabContent extends StatelessWidget {
  const StampTabContent({
    super.key,
    required this.stamps,
    required this.onSelectStamp,
    this.onSelectRecentStamp,
  });

  final List<StampDataModel> stamps;
  final ValueChanged<String> onSelectStamp;
  final void Function(String stampId, List<String> orderedRecentIds)?
  onSelectRecentStamp;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return StampverseEmptyTab(
        icon: Icons.auto_awesome_mosaic_rounded,
        title: LocaleKey.stampverseHomeEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeEmptySubtitle.tr,
      );
    }

    final List<StampDataModel> recentOpened = _resolveRecentOpened(stamps);
    final List<StampDataModel> favorites = _resolveFavorites(stamps);
    final List<String> recentOpenedIds = recentOpened
        .map((StampDataModel item) => item.id)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final int crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        final double contentWidth = (constraints.maxWidth - 48).clamp(
          0,
          double.infinity,
        );
        final double stampTileWidth =
            (contentWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;
        final double recentRowHeight =
            _resolveRowHeight(recentOpened, stampTileWidth) + 32;
        final double favoritesRowHeight =
            _resolveRowHeight(favorites, stampTileWidth) + 32;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            24,
            0,
            24,
            StampverseLayout.contentBottomPadding,
          ),
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

                    return _StampPreviewTile(
                      item: item,
                      stampTileWidth: stampTileWidth,
                      caption: DateFormat('HH:mm').format(openedAt),
                      onTap: () {
                        final onRecentTap = onSelectRecentStamp;
                        if (onRecentTap != null) {
                          onRecentTap(item.id, recentOpenedIds);
                          return;
                        }
                        onSelectStamp(item.id);
                      },
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
              SizedBox(
                height: favoritesRowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, int index) {
                    final StampDataModel item = favorites[index];
                    final DateTime openedAt =
                        item.parsedLastOpenedAt ??
                        item.parsedDate ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                    return _StampPreviewTile(
                      item: item,
                      stampTileWidth: stampTileWidth,
                      caption: DateFormat('HH:mm').format(openedAt),
                      onTap: () => onSelectStamp(item.id),
                    );
                  },
                ),
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

  double _resolveRowHeight(List<StampDataModel> items, double stampTileWidth) {
    if (items.isEmpty) {
      return _resolveDisplayBoundsHeight(null, stampTileWidth);
    }

    double maxHeight = 0;
    for (final StampDataModel item in items) {
      final double itemHeight = _resolveDisplayBoundsHeight(
        item,
        stampTileWidth,
      );
      if (itemHeight > maxHeight) {
        maxHeight = itemHeight;
      }
    }

    return maxHeight > 0
        ? maxHeight
        : _resolveDisplayBoundsHeight(null, stampTileWidth);
  }

  double _resolveDisplayBoundsHeight(
    StampDataModel? item,
    double stampTileWidth,
  ) {
    if (item == null) {
      return stampTileWidth / 0.75;
    }

    final double shapeAspectRatio = item.shapeType.aspectRatio > 0
        ? item.shapeType.aspectRatio
        : 1;
    final double fallbackHeight = stampTileWidth / shapeAspectRatio;

    final double savedBaseWidth = item.previewBaseWidthAtSave ?? 0;
    final double savedBoundsHeight = item.previewBoundsHeightAtSave ?? 0;
    final bool hasSavedMetrics =
        savedBaseWidth.isFinite &&
        savedBaseWidth > 0 &&
        savedBoundsHeight.isFinite &&
        savedBoundsHeight > 0;
    if (!hasSavedMetrics) return fallbackHeight;

    final double scale = stampTileWidth / savedBaseWidth;
    final double displayHeight = savedBoundsHeight * scale;
    if (!displayHeight.isFinite || displayHeight <= 0) return fallbackHeight;
    return displayHeight;
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

class _StampPreviewTile extends StatelessWidget {
  const _StampPreviewTile({
    required this.item,
    required this.stampTileWidth,
    required this.caption,
    required this.onTap,
  });

  final StampDataModel item;
  final double stampTileWidth;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double shapeAspectRatio = item.shapeType.aspectRatio > 0
        ? item.shapeType.aspectRatio
        : 1;
    final double savedBaseWidth = item.previewBaseWidthAtSave ?? 0;
    final double savedBoundsWidth = item.previewBoundsWidthAtSave ?? 0;
    final double savedBoundsHeight = item.previewBoundsHeightAtSave ?? 0;
    final bool hasSavedBounds =
        savedBaseWidth.isFinite &&
        savedBaseWidth > 0 &&
        savedBoundsWidth.isFinite &&
        savedBoundsWidth > 0 &&
        savedBoundsHeight.isFinite &&
        savedBoundsHeight > 0;
    final double scaleFromSavedBase = hasSavedBounds
        ? (stampTileWidth / savedBaseWidth)
        : 1;
    final double displayBoundsWidth = hasSavedBounds
        ? (savedBoundsWidth * scaleFromSavedBase)
        : stampTileWidth;
    final double displayBoundsHeight = hasSavedBounds
        ? (savedBoundsHeight * scaleFromSavedBase)
        : (stampTileWidth / shapeAspectRatio);
    final double displayAspectRatio = displayBoundsHeight > 0
        ? displayBoundsWidth / displayBoundsHeight
        : shapeAspectRatio;

    return SizedBox(
      width: displayBoundsWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StampverseStamp(
            imageUrl: item.imageUrl,
            shapeType: item.shapeType,
            applyShapeClip: false,
            width: displayBoundsWidth,
            aspectRatioOverride: displayAspectRatio,
            showShadow: false,
            onTap: onTap,
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              caption,
              style: StampverseTextStyles.caption(
                color: AppColors.stampverseMutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
