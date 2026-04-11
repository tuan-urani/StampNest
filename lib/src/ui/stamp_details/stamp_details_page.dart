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
  const StampDetailsPageArgs({
    required this.stampId,
    this.collectionName,
    this.browseStampIds,
  });

  final String stampId;
  final String? collectionName;
  final List<String>? browseStampIds;
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
  late final List<String> _browseStampIds;
  late int _currentBrowseIndex;

  @override
  void initState() {
    super.initState();
    _browseStampIds = _resolveBrowseStampIds();
    _currentBrowseIndex = _resolveInitialBrowseIndex(_browseStampIds);
    _cubit = StampDetailsCubit(repository: Get.find<StampverseRepository>())
      ..initialize(stampId: _browseStampIds[_currentBrowseIndex]);
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
              collections: state.collections,
              showDeleteConfirm: _showDeleteConfirm,
              isDeleting: state.isDeleting,
              isAssigningCollection: state.isAssigningCollection,
              canSwipePrevious: _currentBrowseIndex > 0,
              canSwipeNext: _currentBrowseIndex < _browseStampIds.length - 1,
              onSwipePrevious: _onSwipePrevious,
              onSwipeNext: _onSwipeNext,
              onBack: () => Navigator.of(context).pop(_hasChanges),
              onToggleFavorite: () async {
                final bool changed = await _cubit.toggleFavorite(
                  stampId: selected.id,
                );
                if (changed) {
                  _hasChanges = true;
                }
              },
              onAssignCollection: (String collectionName) async {
                final bool assigned = await _cubit.assignCollection(
                  stampId: selected.id,
                  collectionName: collectionName,
                );
                if (assigned) {
                  _hasChanges = true;
                }
                return assigned;
              },
              onDelete: () async {
                final bool deleted = await _cubit.deleteStamp(
                  stampId: selected.id,
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

  List<String> _resolveBrowseStampIds() {
    final List<String> normalized = <String>[];
    final Set<String> unique = <String>{};

    for (final String rawId in widget.args.browseStampIds ?? <String>[]) {
      final String id = rawId.trim();
      if (id.isEmpty || unique.contains(id)) continue;
      unique.add(id);
      normalized.add(id);
    }

    final String seed = widget.args.stampId.trim();
    if (seed.isNotEmpty && !unique.contains(seed)) {
      normalized.add(seed);
    }

    return normalized.isEmpty ? <String>[seed] : normalized;
  }

  int _resolveInitialBrowseIndex(List<String> ids) {
    final String seed = widget.args.stampId.trim();
    final int index = ids.indexOf(seed);
    return index < 0 ? 0 : index;
  }

  Future<void> _onSwipeToIndex(int nextIndex) async {
    if (nextIndex < 0 || nextIndex >= _browseStampIds.length) return;

    setState(() {
      _showDeleteConfirm = false;
      _currentBrowseIndex = nextIndex;
    });

    await _cubit.refresh(stampId: _browseStampIds[nextIndex]);
  }

  void _onSwipePrevious() {
    _onSwipeToIndex(_currentBrowseIndex - 1);
  }

  void _onSwipeNext() {
    _onSwipeToIndex(_currentBrowseIndex + 1);
  }
}

StampDetailsPageArgs resolveStampDetailsPageArgs(Object? raw) {
  if (raw is StampDetailsPageArgs) return raw;
  if (raw is Map<String, dynamic>) {
    final dynamic rawBrowseIds = raw['browseStampIds'];
    final List<String> browseStampIds = rawBrowseIds is List
        ? rawBrowseIds
              .map((dynamic value) => value.toString().trim())
              .where((String value) => value.isNotEmpty)
              .toList(growable: false)
        : <String>[];
    return StampDetailsPageArgs(
      stampId: (raw['stampId'] as String? ?? '').trim(),
      collectionName: (raw['collectionName'] as String?)?.trim(),
      browseStampIds: browseStampIds,
    );
  }
  return const StampDetailsPageArgs(stampId: '');
}
