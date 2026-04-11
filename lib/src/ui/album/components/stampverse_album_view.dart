import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseAlbumView extends StatelessWidget {
  const StampverseAlbumView({
    super.key,
    required this.stamps,
    required this.title,
    required this.onBack,
    required this.onSelectStamp,
  });

  final List<StampDataModel> stamps;
  final String title;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectStamp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: <Widget>[
                  StampverseIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  Text(title, style: StampverseTextStyles.sectionTitle()),
                  const Spacer(),
                  const StampverseIconButton(icon: Icons.more_horiz_rounded),
                ],
              ),
            ),
            Expanded(
              child: stamps.isEmpty
                  ? Center(
                      child: Text(
                        LocaleKey.stampverseAlbumEmpty.tr,
                        style: StampverseTextStyles.heroTitle(
                          color: AppColors.stampverseMutedText,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                            childAspectRatio: 3 / 4,
                          ),
                      itemCount: stamps.length,
                      itemBuilder: (_, int index) {
                        final StampDataModel item = stamps[index];
                        return StampverseStamp(
                          imageUrl: item.imageUrl,
                          shapeType: item.shapeType,
                          applyShapeClip: false,
                          showShadow: false,
                          onTap: () => onSelectStamp(item.id),
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
