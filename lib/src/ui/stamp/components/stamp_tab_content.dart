import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
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
  });

  final List<StampDataModel> stamps;
  final ValueChanged<String> onSelectStamp;

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
