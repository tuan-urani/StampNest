import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/album/interactor/album_page_state.dart';

class AlbumPageCubit extends Cubit<AlbumPageState> {
  AlbumPageCubit({required StampverseRepository repository})
    : _repository = repository,
      super(AlbumPageState.initial());

  final StampverseRepository _repository;

  Future<void> initialize({required String collectionName}) async {
    if (state.isInitialized) return;
    await refresh(collectionName: collectionName, initialLoad: true);
  }

  Future<void> refresh({
    required String collectionName,
    bool initialLoad = false,
  }) async {
    emit(state.copyWith(isLoading: initialLoad, errorMessage: null));

    final List<StampDataModel> stamps = await _repository.readCache();
    final List<StampDataModel> albumStamps = stamps
        .where(
          (StampDataModel item) => (item.album?.trim() ?? '') == collectionName,
        )
        .toList(growable: false);

    emit(
      state.copyWith(
        stamps: albumStamps,
        isLoading: false,
        isInitialized: true,
      ),
    );
  }

  Future<void> selectStamp(String id) async {
    final int index = state.stamps.indexWhere(
      (StampDataModel item) => item.id == id,
    );
    if (index < 0) return;

    final List<StampDataModel> allStamps = await _repository.readCache();
    final int globalIndex = allStamps.indexWhere(
      (StampDataModel item) => item.id == id,
    );
    if (globalIndex < 0) return;

    final StampDataModel selected = allStamps[globalIndex];
    final String openedAt = DateTime.now().toIso8601String();
    final List<StampDataModel> updated = List<StampDataModel>.from(allStamps);
    updated[globalIndex] = selected.copyWith(lastOpenedAt: openedAt);

    await _repository.saveCache(updated);
  }
}
