import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_state.dart';

class SaveStampCubit extends Cubit<SaveStampState> {
  SaveStampCubit({required StampverseRepository repository})
    : _repository = repository,
      super(SaveStampState.initial());

  final StampverseRepository _repository;

  Future<void> initialize() async {
    if (state.isInitialized) return;

    final List<StampDataModel> cachedStamps = await _repository.readCache();
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(cachedStamps);

    emit(state.copyWith(collections: collections, isInitialized: true));
  }

  Future<bool> saveStamp({
    required String stampedImageUrl,
    required String sourceImageUrl,
    required StampShapeType shapeType,
    required String rawName,
    required String rawCollection,
  }) async {
    if (stampedImageUrl.isEmpty || sourceImageUrl.isEmpty) return false;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    final String stampName = rawName.trim();
    final String collectionName = rawCollection.trim();
    final String dateIso = DateTime.now().toIso8601String();

    final List<StampDataModel> currentStamps = await _repository.readCache();
    final StampDataModel optimisticStamp = StampDataModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: stampName,
      imageUrl: stampedImageUrl,
      sourceImageUrl: sourceImageUrl,
      date: dateIso,
      shapeType: shapeType,
      album: collectionName.isEmpty ? null : collectionName,
      lastOpenedAt: dateIso,
    );

    final List<StampDataModel> optimisticList = <StampDataModel>[
      optimisticStamp,
      ...currentStamps,
    ];

    final List<String> optimisticCollections = collectionName.isEmpty
        ? await _repository.mergeCollectionsWithStamps(optimisticList)
        : await _repository.addCollection(collectionName);

    await _repository.saveCache(optimisticList);

    emit(
      state.copyWith(
        collections: optimisticCollections,
        isSaving: false,
        errorMessage: null,
      ),
    );
    return true;
  }
}
