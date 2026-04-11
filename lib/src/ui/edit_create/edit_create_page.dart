import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/edit_board/edit_board_page.dart';
import 'package:stamp_camera/src/ui/edit_create/components/stampverse_edit_create_view.dart';
import 'package:stamp_camera/src/ui/edit_create/interactor/edit_create_page_cubit.dart';
import 'package:stamp_camera/src/ui/edit_create/interactor/edit_create_page_state.dart';
import 'package:stamp_camera/src/ui/routing/creative_router.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class EditCreatePage extends StatefulWidget {
  const EditCreatePage({super.key});

  @override
  State<EditCreatePage> createState() => _EditCreatePageState();
}

class _EditCreatePageState extends State<EditCreatePage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<EditCreatePageCubit>(
        create: (_) =>
            EditCreatePageCubit(repository: Get.find<StampverseRepository>()),
        child: BlocBuilder<EditCreatePageCubit, EditCreatePageState>(
          builder: (BuildContext context, EditCreatePageState state) {
            final EditCreatePageCubit cubit = context
                .read<EditCreatePageCubit>();
            return StampverseEditCreateView(
              nameController: _nameController,
              onBack: () => Navigator.of(context).pop(false),
              onSave: () async {
                final String? boardId = await cubit.createEditBoardFromName(
                  _nameController.text,
                );
                if (!context.mounted) return;
                if (boardId == null || boardId.isEmpty) {
                  Navigator.of(context).pop(false);
                  return;
                }
                final Object? result = await Navigator.of(context).pushNamed(
                  CreativeRouter.editBoard,
                  arguments: EditBoardPageArgs(boardId: boardId),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop(result == true);
              },
            );
          },
        ),
      ),
    );
  }
}
