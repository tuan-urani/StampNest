import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/edit_board/components/stampverse_edit_board_view.dart';
import 'package:stamp_camera/src/ui/edit_board/interactor/edit_board_page_cubit.dart';
import 'package:stamp_camera/src/ui/edit_board/interactor/edit_board_page_state.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class EditBoardPageArgs {
  const EditBoardPageArgs({required this.boardId});

  final String boardId;
}

class EditBoardPage extends StatefulWidget {
  const EditBoardPage({super.key, required this.args});

  final EditBoardPageArgs args;

  @override
  State<EditBoardPage> createState() => _EditBoardPageState();
}

class _EditBoardPageState extends State<EditBoardPage> {
  bool _hasChanges = false;
  late final EditBoardPageCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EditBoardPageCubit(repository: Get.find<StampverseRepository>())
      ..initialize(boardId: widget.args.boardId);
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
      child: BlocProvider<EditBoardPageCubit>.value(
        value: _cubit,
        child: BlocBuilder<EditBoardPageCubit, EditBoardPageState>(
          builder: (BuildContext context, EditBoardPageState state) {
            final board = state.currentBoard;
            if (board == null) {
              return const SizedBox.shrink();
            }

            return StampverseEditBoardView(
              board: board,
              allBoards: state.allBoards,
              stamps: state.stamps,
              onBack: () => Navigator.of(context).pop(_hasChanges),
              onSaveBoard: (board) async {
                await _cubit.saveBoard(board);
                _hasChanges = true;
              },
            );
          },
        ),
      ),
    );
  }
}

EditBoardPageArgs resolveEditBoardPageArgs(Object? raw) {
  if (raw is EditBoardPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    return EditBoardPageArgs(boardId: (raw['boardId'] as String? ?? '').trim());
  }
  return const EditBoardPageArgs(boardId: '');
}
