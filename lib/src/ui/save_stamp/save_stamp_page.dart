import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/save_stamp/components/stampverse_save_view.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_cubit.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_state.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class SaveStampPageArgs {
  const SaveStampPageArgs({required this.imageUrl, required this.shapeType});

  final String imageUrl;
  final StampShapeType shapeType;
}

class SaveStampPage extends StatefulWidget {
  const SaveStampPage({super.key, required this.args});

  final SaveStampPageArgs args;

  @override
  State<SaveStampPage> createState() => _SaveStampPageState();
}

class _SaveStampPageState extends State<SaveStampPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _collectionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _collectionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<SaveStampCubit>(
        create: (_) =>
            SaveStampCubit(repository: Get.find<StampverseRepository>())
              ..initialize(),
        child: BlocBuilder<SaveStampCubit, SaveStampState>(
          builder: (BuildContext context, SaveStampState state) {
            final SaveStampCubit cubit = context.read<SaveStampCubit>();
            return StampverseSaveView(
              imageUrl: widget.args.imageUrl,
              shapeType: widget.args.shapeType,
              nameController: _nameController,
              collectionController: _collectionController,
              collections: state.collections,
              defaultCollection: '',
              onBack: () => Navigator.of(context).pop(false),
              onSave: () async {
                final String rawName = _nameController.text.trim().isEmpty
                    ? LocaleKey.stampverseSaveDefaultName.tr
                    : _nameController.text.trim();
                final String rawCollection = _collectionController.text.trim();

                final bool saved = await cubit.saveStamp(
                  imageUrl: widget.args.imageUrl,
                  shapeType: widget.args.shapeType,
                  rawName: rawName,
                  rawCollection: rawCollection,
                );
                if (!context.mounted) return;
                if (saved) {
                  Navigator.of(context).pop(true);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

SaveStampPageArgs resolveSaveStampPageArgs(Object? raw) {
  if (raw is SaveStampPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    return SaveStampPageArgs(
      imageUrl: (raw['imageUrl'] as String? ?? '').trim(),
      shapeType: stampShapeFromRaw(raw['shapeType']?.toString()),
    );
  }
  return const SaveStampPageArgs(
    imageUrl: '',
    shapeType: StampShapeType.scallop,
  );
}
