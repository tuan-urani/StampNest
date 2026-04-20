import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/save_stamp/components/stampverse_save_view.dart';
import 'package:stamp_camera/src/ui/save_stamp/helpers/stampverse_save_stamp_export.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_cubit.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_state.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class SaveStampPageArgs {
  const SaveStampPageArgs({
    required this.sourceImageUrl,
    required this.shapeType,
  });

  final String sourceImageUrl;
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

  void _showExportFailedMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.stampverseDangerSoft,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.stampverseDanger.withValues(alpha: 0.35),
            ),
          ),
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.stampverseDanger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.stampverseDanger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

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
    return Scaffold(
      backgroundColor: AppColors.stampverseBackground,
      body: BlocProvider<SaveStampCubit>(
        create: (_) =>
            SaveStampCubit(repository: Get.find<StampverseRepository>())
              ..initialize(),
        child: BlocBuilder<SaveStampCubit, SaveStampState>(
          builder: (BuildContext context, SaveStampState state) {
            final SaveStampCubit cubit = context.read<SaveStampCubit>();
            return StampverseSaveView(
              imageUrl: widget.args.sourceImageUrl,
              shapeType: widget.args.shapeType,
              nameController: _nameController,
              collectionController: _collectionController,
              collections: state.collections,
              defaultCollection: '',
              onBack: () => Navigator.of(context).pop(false),
              onSave:
                  (
                    double rotationRadians,
                    double previewBaseWidth,
                    double previewBoundsWidth,
                    double previewBoundsHeight,
                  ) async {
                    final String rawName = _nameController.text.trim().isEmpty
                        ? LocaleKey.stampverseSaveDefaultName.tr
                        : _nameController.text.trim();
                    final String rawCollection = _collectionController.text
                        .trim();
                    final String? exportedImageUrl =
                        await exportSaveStampImageDataUrl(
                          imageUrl: widget.args.sourceImageUrl,
                          shapeType: widget.args.shapeType,
                          baseWidth: previewBaseWidth,
                          rotationRadians: rotationRadians,
                        );
                    if (!context.mounted) return;
                    if (exportedImageUrl == null || exportedImageUrl.isEmpty) {
                      _showExportFailedMessage(
                        LocaleKey.stampverseSaveExportFailed.tr,
                      );
                      return;
                    }

                    final bool saved = await cubit.saveStamp(
                      stampedImageUrl: exportedImageUrl,
                      sourceImageUrl: widget.args.sourceImageUrl,
                      shapeType: widget.args.shapeType,
                      rotationRadians: rotationRadians,
                      previewBaseWidthAtSave: previewBaseWidth,
                      previewBoundsWidthAtSave: previewBoundsWidth,
                      previewBoundsHeightAtSave: previewBoundsHeight,
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
      sourceImageUrl: (raw['sourceImageUrl'] as String? ?? '').trim(),
      shapeType: stampShapeFromRaw(raw['shapeType']?.toString()),
    );
  }
  return const SaveStampPageArgs(
    sourceImageUrl: '',
    shapeType: StampShapeType.scallop,
  );
}
