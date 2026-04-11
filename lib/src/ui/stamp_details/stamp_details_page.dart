import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stamp_details/components/stampverse_details_view.dart';
import 'package:stamp_camera/src/ui/stamp_details/interactor/stamp_details_cubit.dart';
import 'package:stamp_camera/src/ui/stamp_details/interactor/stamp_details_state.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampDetailsPageArgs {
  const StampDetailsPageArgs({required this.stampId, this.collectionName});

  final String stampId;
  final String? collectionName;
}

class StampDetailsPage extends StatefulWidget {
  const StampDetailsPage({super.key, required this.args});

  final StampDetailsPageArgs args;

  @override
  State<StampDetailsPage> createState() => _StampDetailsPageState();
}

class _StampDetailsPageState extends State<StampDetailsPage> {
  bool _showDeleteConfirm = false;
  bool _hasChanges = false;
  late final StampDetailsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = StampDetailsCubit(repository: Get.find<StampverseRepository>())
      ..initialize(stampId: widget.args.stampId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<StampDetailsCubit>.value(
        value: _cubit,
        child: BlocBuilder<StampDetailsCubit, StampDetailsState>(
          builder: (BuildContext context, StampDetailsState state) {
            final StampDataModel? selected = state.stamp;

            if (selected == null) {
              return Scaffold(
                backgroundColor: AppColors.stampverseBackground,
                body: Center(
                  child: Text(
                    LocaleKey.stampverseAlbumEmpty.tr,
                    style: StampverseTextStyles.body(),
                  ),
                ),
              );
            }

            return StampverseDetailsView(
              stamp: selected,
              showDeleteConfirm: _showDeleteConfirm,
              isDeleting: state.isDeleting,
              onBack: () => Navigator.of(context).pop(_hasChanges),
              onToggleFavorite: () async {
                final bool changed = await _cubit.toggleFavorite(
                  stampId: selected.id,
                );
                if (changed) {
                  _hasChanges = true;
                }
              },
              onDelete: () async {
                final bool deleted = await _cubit.deleteStamp(
                  stampId: widget.args.stampId,
                );
                if (!context.mounted) return;
                if (deleted) {
                  Navigator.of(context).pop(true);
                }
              },
              onDeleteConfirmVisible: (bool value) {
                setState(() {
                  _showDeleteConfirm = value;
                });
              },
            );
          },
        ),
      ),
    );
  }
}

StampDetailsPageArgs resolveStampDetailsPageArgs(Object? raw) {
  if (raw is StampDetailsPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    return StampDetailsPageArgs(
      stampId: (raw['stampId'] as String? ?? '').trim(),
      collectionName: (raw['collectionName'] as String?)?.trim(),
    );
  }
  return const StampDetailsPageArgs(stampId: '');
}
