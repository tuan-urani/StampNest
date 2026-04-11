import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/stamp/interactor/stamp_page_state.dart';

class StampPageCubit extends Cubit<StampPageState> {
  StampPageCubit({
    required StampverseRepository repository,
    required ImagePicker imagePicker,
  }) : _repository = repository,
       _imagePicker = imagePicker,
       super(StampPageState.initial());

  final StampverseRepository _repository;
  final ImagePicker _imagePicker;

  Future<void> initialize() async {
    if (state.isInitialized) return;
    await refresh(initialLoad: true);
  }

  Future<void> refresh({bool initialLoad = false}) async {
    emit(state.copyWith(isLoading: initialLoad, errorMessage: null));

    final List<StampDataModel> stamps = await _repository.readCache();
    emit(state.copyWith(stamps: stamps, isLoading: false, isInitialized: true));
  }

  Future<void> selectStamp(String id) async {
    final int index = state.stamps.indexWhere(
      (StampDataModel item) => item.id == id,
    );
    if (index < 0) return;

    final StampDataModel selected = state.stamps[index];
    final String openedAt = DateTime.now().toIso8601String();
    final List<StampDataModel> updated = List<StampDataModel>.from(
      state.stamps,
    );
    updated[index] = selected.copyWith(lastOpenedAt: openedAt);

    emit(state.copyWith(stamps: updated));
    await _repository.saveCache(updated);
  }

  Future<String?> pickGalleryImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null) return null;

      final String mimeType = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpeg';
      final List<int> bytes = await file.readAsBytes();
      final String encoded = base64Encode(bytes);
      return 'data:image/$mimeType;base64,$encoded';
    } catch (_) {
      emit(state.copyWith(errorMessage: 'CAMERA_PERMISSION_ERROR'));
      return null;
    }
  }
}
