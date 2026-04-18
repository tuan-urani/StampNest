import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/creative/components/creative_mode_segment.dart';
import 'package:stamp_camera/src/ui/creative/components/creative_template_content.dart';
import 'package:stamp_camera/src/ui/creative/components/creative_tab_content.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_cubit.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_page_state.dart';
import 'package:stamp_camera/src/ui/edit_board/edit_board_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_state.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/routing/creative_router.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_tab_scaffold.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_top_round_action_button.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CreativePage extends StatelessWidget {
  const CreativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<CreativePageCubit>(
        create: (_) =>
            CreativePageCubit(repository: Get.find<StampverseRepository>())
              ..initialize(),
        child: BlocBuilder<CreativePageCubit, CreativePageState>(
          builder: (BuildContext context, CreativePageState state) {
            final CreativePageCubit cubit = context.read<CreativePageCubit>();
            final bool isBoardsMode = state.viewMode == CreativeViewMode.boards;
            final bool isSelectionMode =
                isBoardsMode && state.selectedBoardIds.isNotEmpty;

            return BlocListener<MainBloc, MainState>(
              bloc: Get.find<MainBloc>(),
              listenWhen: (MainState previous, MainState current) =>
                  previous.currentPage != current.currentPage,
              listener: (_, MainState mainState) {
                if (mainState.currentPage == BottomNavigationPage.creative) {
                  cubit.refresh();
                }
              },
              child: StampverseTabScaffold(
                title: LocaleKey.stampverseHomeTabEdit.tr,
                leading: isSelectionMode
                    ? StampverseTopRoundActionButton(
                        icon: Icons.close_rounded,
                        onTap: cubit.clearEditBoardSelection,
                      )
                    : null,
                trailing: isSelectionMode
                    ? StampverseTopRoundActionButton(
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.stampverseDanger,
                        onTap: () {
                          cubit.deleteSelectedEditBoards();
                        },
                      )
                    : StampverseTopRoundActionButton(
                        icon: Icons.settings_rounded,
                        onTap: () async {
                          await Get.toNamed(CommonRouter.settings);
                          if (!context.mounted) return;
                          await cubit.refresh();
                        },
                      ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: CreativeModeSegment(
                        mode: state.viewMode,
                        onChanged: cubit.changeViewMode,
                      ),
                    ),
                    Expanded(
                      child: state.viewMode == CreativeViewMode.templates
                          ? CreativeTemplateContent(
                              templates: state.templates,
                              onSelectTemplate: (template) async {
                                final String templateName =
                                    template.nameLocaleKey.tr;
                                final String? boardId = await cubit
                                    .createBoardFromTemplate(
                                      template: template,
                                      templateName: templateName,
                                    );
                                if (!context.mounted) return;
                                if (boardId == null || boardId.isEmpty) return;

                                final Object? result = await Get.toNamed(
                                  CreativeRouter.editBoard,
                                  arguments: EditBoardPageArgs(
                                    boardId: boardId,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (result == true) {
                                  await cubit.refresh();
                                }
                              },
                            )
                          : CreativeTabContent(
                              boards: state.boards,
                              selectedBoardIds: state.selectedBoardIds,
                              onOpenTemplates: () => cubit.changeViewMode(
                                CreativeViewMode.templates,
                              ),
                              onOpenBoard: (String boardId) async {
                                final Object? result = await Get.toNamed(
                                  CreativeRouter.editBoard,
                                  arguments: EditBoardPageArgs(
                                    boardId: boardId,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (result == true) {
                                  await cubit.refresh();
                                }
                              },
                              onStartSelection: cubit.startEditBoardSelection,
                              onToggleSelection: cubit.toggleEditBoardSelection,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
