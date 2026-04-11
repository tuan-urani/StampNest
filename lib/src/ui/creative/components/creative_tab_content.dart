import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_empty_tab.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_layout.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CreativeTabContent extends StatelessWidget {
  const CreativeTabContent({
    super.key,
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
      return StampverseEmptyTab(
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
