import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_collection_summary.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CollectionTabContent extends StatelessWidget {
  const CollectionTabContent({
    super.key,
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
      return StampverseEmptyTab(
        icon: Icons.collections_bookmark_outlined,
        title: LocaleKey.stampverseHomeCollectionEmptyTitle.tr,
        subtitle: LocaleKey.stampverseHomeCollectionEmptySubtitle.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        StampverseLayout.contentBottomPadding,
      ),
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
