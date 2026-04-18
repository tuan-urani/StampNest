import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/camera/components/stampverse_camera_view.dart';
import 'package:stamp_camera/src/ui/camera/interactor/camera_page_cubit.dart';
import 'package:stamp_camera/src/ui/camera/interactor/camera_page_state.dart';
import 'package:stamp_camera/src/ui/routing/stamp_router.dart';
import 'package:stamp_camera/src/ui/save_stamp/save_stamp_page.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class CameraPageArgs {
  const CameraPageArgs({
    this.draftImage,
    this.initialShape = StampShapeType.scallop,
  });

  final String? draftImage;
  final StampShapeType initialShape;
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key, this.args = const CameraPageArgs()});

  final CameraPageArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: BlocProvider<CameraPageCubit>(
        create: (_) => CameraPageCubit(
          initialDraftImage: args.draftImage,
          initialShape: args.initialShape,
        ),
        child: BlocBuilder<CameraPageCubit, CameraPageState>(
          builder: (BuildContext context, CameraPageState state) {
            final CameraPageCubit cubit = context.read<CameraPageCubit>();
            return StampverseCameraView(
              draftImage: state.draftImage,
              selectedShape: state.selectedShape,
              onShapeChanged: cubit.updateShape,
              onBack: () => Navigator.of(context).pop(false),
              onCaptureLiveCamera: (String imageDataUrl) async {
                final Object? result = await Get.toNamed(
                  StampRouter.saveStamp,
                  arguments: SaveStampPageArgs(
                    sourceImageUrl: imageDataUrl,
                    shapeType: state.selectedShape,
                  ),
                );
                if (!context.mounted) return false;
                if (result == true) {
                  Navigator.of(context).pop(true);
                  return true;
                }
                return false;
              },
              onReset: cubit.resetDraft,
              onConfirmCrop: (String croppedImageDataUrl) async {
                final Object? result = await Get.toNamed(
                  StampRouter.saveStamp,
                  arguments: SaveStampPageArgs(
                    sourceImageUrl: croppedImageDataUrl,
                    shapeType: state.selectedShape,
                  ),
                );
                if (!context.mounted) return false;
                if (result == true) {
                  Navigator.of(context).pop(true);
                  return true;
                }
                return false;
              },
            );
          },
        ),
      ),
    );
  }
}

CameraPageArgs resolveCameraPageArgs(Object? raw) {
  if (raw is CameraPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    return CameraPageArgs(
      draftImage: (raw['draftImage'] as String?)?.trim(),
      initialShape: stampShapeFromRaw(raw['shapeType']?.toString()),
    );
  }
  return const CameraPageArgs();
}
