import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/stamp_details/interactor/stamp_details_state.dart';

class StampDetailsCubit extends Cubit<StampDetailsState> {
  StampDetailsCubit({required StampverseRepository repository})
    : _repository = repository,
      super(StampDetailsState.initial());

  final StampverseRepository _repository;

  Future<void> initialize({required String stampId}) async {
    if (stampId.isEmpty) {
      emit(state.copyWith(stamp: null, isInitialized: true));
      return;
    }

    final List<StampDataModel> stamps = await _repository.readCache();
    final StampDataModel? stamp = _findStamp(stamps, stampId);
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(stamps);
    emit(
      state.copyWith(
        stamp: stamp,
        collections: collections,
        isInitialized: true,
        errorMessage: null,
      ),
    );
  }

  Future<void> refresh({required String stampId}) async {
    final List<StampDataModel> stamps = await _repository.readCache();
    final StampDataModel? stamp = _findStamp(stamps, stampId);
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(stamps);
    emit(
      state.copyWith(
        stamp: stamp,
        collections: collections,
        errorMessage: null,
      ),
    );
  }

  Future<bool> toggleFavorite({required String stampId}) async {
    final List<StampDataModel> stamps = await _repository.readCache();
    final int index = stamps.indexWhere(
      (StampDataModel item) => item.id == stampId,
    );
    if (index < 0) return false;

    final List<StampDataModel> updated = List<StampDataModel>.from(stamps);
    final StampDataModel selected = updated[index];
    updated[index] = selected.copyWith(isFavorite: !selected.isFavorite);

    await _repository.saveCache(updated);
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(updated);
    emit(
      state.copyWith(
        stamp: updated[index],
        collections: collections,
        errorMessage: null,
      ),
    );
    return true;
  }

  Future<bool> assignCollection({
    required String stampId,
    required String collectionName,
  }) async {
    final String normalizedCollection = collectionName.trim();
    if (stampId.isEmpty || normalizedCollection.isEmpty) {
      return false;
    }

    emit(state.copyWith(isAssigningCollection: true, errorMessage: null));

    final List<StampDataModel> stamps = await _repository.readCache();
    final int index = stamps.indexWhere(
      (StampDataModel item) => item.id == stampId,
    );
    if (index < 0) {
      emit(state.copyWith(isAssigningCollection: false));
      return false;
    }

    final List<StampDataModel> updated = List<StampDataModel>.from(stamps);
    updated[index] = updated[index].copyWith(album: normalizedCollection);

    await _repository.saveCache(updated);
    final List<String> collections = await _repository.addCollection(
      normalizedCollection,
    );

    emit(
      state.copyWith(
        stamp: updated[index],
        collections: collections,
        isAssigningCollection: false,
        errorMessage: null,
      ),
    );
    return true;
  }

  Future<bool> deleteStamp({required String stampId}) async {
    if (stampId.isEmpty) return false;

    emit(state.copyWith(isDeleting: true, errorMessage: null));

    final List<StampDataModel> stamps = await _repository.readCache();
    final List<StampDataModel> updated = stamps
        .where((StampDataModel item) => item.id != stampId)
        .toList(growable: false);

    await _repository.saveCache(updated);
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(updated);

    emit(
      state.copyWith(
        stamp: null,
        collections: collections,
        isDeleting: false,
        errorMessage: null,
      ),
    );
    return true;
  }

  StampDataModel? _findStamp(List<StampDataModel> stamps, String stampId) {
    for (final StampDataModel item in stamps) {
      if (item.id == stampId) return item;
    }
    return null;
  }
}
