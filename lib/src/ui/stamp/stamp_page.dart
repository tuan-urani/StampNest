import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/camera/camera_page.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_bloc.dart';
import 'package:stamp_camera/src/ui/main/bloc/main_state.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/routing/stamp_router.dart';
import 'package:stamp_camera/src/ui/stamp/components/stamp_tab_content.dart';
import 'package:stamp_camera/src/ui/stamp/interactor/stamp_page_cubit.dart';
import 'package:stamp_camera/src/ui/stamp/interactor/stamp_page_state.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_tab_scaffold.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_top_round_action_button.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampPage extends StatelessWidget {
  const StampPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<StampPageCubit>(
        create: (_) => StampPageCubit(
          repository: Get.find<StampverseRepository>(),
          imagePicker: ImagePicker(),
        )..initialize(),
        child: BlocBuilder<StampPageCubit, StampPageState>(
          builder: (BuildContext context, StampPageState state) {
            final StampPageCubit cubit = context.read<StampPageCubit>();
            return BlocListener<MainBloc, MainState>(
              bloc: Get.find<MainBloc>(),
              listenWhen: (MainState previous, MainState current) =>
                  previous.currentPage != current.currentPage,
              listener: (_, MainState mainState) {
                if (mainState.currentPage == BottomNavigationPage.stamp) {
                  cubit.refresh();
                }
              },
              child: StampverseTabScaffold(
                title: LocaleKey.stampverseHomeTabStamp.tr,
                trailing: StampverseTopRoundActionButton(
                  icon: Icons.settings_rounded,
                  onTap: () async {
                    await Get.toNamed(CommonRouter.settings);
                    if (!context.mounted) return;
                    await cubit.refresh();
                  },
                ),
                showFab: true,
                onOpenCamera: () async {
                  final Object? result = await Get.toNamed(
                    StampRouter.camera,
                    arguments: const CameraPageArgs(),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    await cubit.refresh();
                  }
                },
                onOpenGallery: () async {
                  final String? draftImage = await cubit.pickGalleryImage();
                  if (!context.mounted) return;
                  if (draftImage == null || draftImage.isEmpty) return;

                  final Object? result = await Get.toNamed(
                    StampRouter.camera,
                    arguments: CameraPageArgs(draftImage: draftImage),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    await cubit.refresh();
                  }
                },
                child: StampTabContent(
                  stamps: state.stamps,
                  onSelectRecentStamp:
                      (String id, List<String> orderedRecentIds) async {
                        await cubit.selectStamp(id);
                        if (!context.mounted) return;

                        final Object? result = await Get.toNamed(
                          StampRouter.stampDetails,
                          arguments: StampDetailsPageArgs(
                            stampId: id,
                            browseStampIds: orderedRecentIds,
                          ),
                        );
                        if (!context.mounted) return;
                        if (result == true) {
                          await cubit.refresh();
                        }
                      },
                  onSelectStamp: (String id) async {
                    await cubit.selectStamp(id);
                    if (!context.mounted) return;

                    final Object? result = await Get.toNamed(
                      StampRouter.stampDetails,
                      arguments: StampDetailsPageArgs(stampId: id),
                    );
                    if (!context.mounted) return;
                    if (result == true) {
                      await cubit.refresh();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
