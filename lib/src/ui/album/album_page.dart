import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/album/components/stampverse_album_view.dart';
import 'package:stamp_camera/src/ui/album/interactor/album_page_cubit.dart';
import 'package:stamp_camera/src/ui/album/interactor/album_page_state.dart';
import 'package:stamp_camera/src/ui/routing/collection_router.dart';
import 'package:stamp_camera/src/ui/stamp_details/stamp_details_page.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class AlbumPageArgs {
  const AlbumPageArgs({required this.collectionName});

  final String collectionName;
}

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key, required this.args});

  final AlbumPageArgs args;

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<AlbumPageCubit>(
        create: (_) =>
            AlbumPageCubit(repository: Get.find<StampverseRepository>())
              ..initialize(collectionName: widget.args.collectionName),
        child: BlocBuilder<AlbumPageCubit, AlbumPageState>(
          builder: (BuildContext context, AlbumPageState state) {
            final AlbumPageCubit cubit = context.read<AlbumPageCubit>();
            return StampverseAlbumView(
              stamps: state.stamps,
              title: widget.args.collectionName.trim().isNotEmpty
                  ? widget.args.collectionName
                  : LocaleKey.stampverseAlbumTitle.tr,
              onBack: () => Navigator.of(context).pop(_hasChanges),
              onSelectStamp: (String id) async {
                await cubit.selectStamp(id);
                if (!context.mounted) return;
                final Object? result = await Get.toNamed(
                  CollectionRouter.stampDetails,
                  arguments: StampDetailsPageArgs(
                    stampId: id,
                    collectionName: widget.args.collectionName,
                  ),
                );
                if (!context.mounted) return;
                if (result == true) {
                  _hasChanges = true;
                  await cubit.refresh(
                    collectionName: widget.args.collectionName,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

AlbumPageArgs resolveAlbumPageArgs(Object? raw) {
  if (raw is AlbumPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    return AlbumPageArgs(
      collectionName: (raw['collectionName'] as String? ?? '').trim(),
    );
  }
  return const AlbumPageArgs(collectionName: '');
}
