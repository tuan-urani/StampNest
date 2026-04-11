import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/album/album_page.dart';
import 'package:stamp_camera/src/ui/camera/camera_page.dart';
import 'package:stamp_camera/src/ui/collection/components/collection_tab_content.dart';
import 'package:stamp_camera/src/ui/collection/interactor/collection_page_cubit.dart';
import 'package:stamp_camera/src/ui/collection/interactor/collection_page_state.dart';
import 'package:stamp_camera/src/ui/routing/collection_router.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/routing/stamp_router.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_tab_scaffold.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_top_round_action_button.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_view_helper.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<CollectionPageCubit>(
        create: (_) => CollectionPageCubit(
          repository: Get.find<StampverseRepository>(),
          imagePicker: ImagePicker(),
        )..initialize(),
        child: BlocBuilder<CollectionPageCubit, CollectionPageState>(
          builder: (BuildContext context, CollectionPageState state) {
            final CollectionPageCubit cubit = context
                .read<CollectionPageCubit>();
            return StampverseTabScaffold(
              title: LocaleKey.stampverseHomeTabCollection.tr,
              trailing: StampverseTopRoundActionButton(
                icon: Icons.settings_rounded,
                onTap: () =>
                    Navigator.of(context).pushNamed(CommonRouter.settings),
              ),
              showFab: true,
              onOpenCamera: () async {
                final Object? result = await Navigator.of(context).pushNamed(
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

                final Object? result = await Navigator.of(context).pushNamed(
                  StampRouter.camera,
                  arguments: CameraPageArgs(draftImage: draftImage),
                );
                if (!context.mounted) return;
                if (result == true) {
                  await cubit.refresh();
                }
              },
              child: CollectionTabContent(
                collections: groupCollectionSummaries(state.stamps),
                onOpenCollection: (String name) async {
                  final Object? result = await Navigator.of(context).pushNamed(
                    CollectionRouter.album,
                    arguments: AlbumPageArgs(collectionName: name),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    await cubit.refresh();
                  }
                },
                onSelectStamp: (String id) async {
                  await cubit.selectStamp(id);
                  if (!context.mounted) return;

                  final Object? result = await Navigator.of(context).pushNamed(
                    CollectionRouter.stampDetails,
                    arguments: StampDetailsPageArgs(stampId: id),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    await cubit.refresh();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
