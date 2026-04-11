import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/settings/interactor/settings_page_state.dart';

class SettingsPageCubit extends Cubit<SettingsPageState> {
  SettingsPageCubit({required StampverseRepository repository})
    : _repository = repository,
      super(const SettingsPageState());

  final StampverseRepository _repository;

  Future<void> initialize() async {
    if (state.isInitialized) return;
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    final List<StampDataModel> stamps = await _repository.readCache();
    final List<String> collections = await _repository
        .mergeCollectionsWithStamps(stamps);

    emit(
      state.copyWith(
        stampsCount: stamps.length,
        collectionsCount: collections.length,
        isRefreshing: false,
        isInitialized: true,
      ),
    );
  }

  Future<void> clearLocalData() async {
    await _repository.clearLocalData();
    emit(
      state.copyWith(
        stampsCount: 0,
        collectionsCount: 0,
        isRefreshing: false,
        errorMessage: null,
      ),
    );
  }
}
