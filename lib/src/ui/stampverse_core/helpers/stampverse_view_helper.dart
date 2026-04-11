import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_data_model.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_collection_summary.dart';

List<StampverseCollectionSummary> groupCollectionSummaries(
  List<StampDataModel> stamps,
) {
  final Map<String, List<StampDataModel>> grouped =
      <String, List<StampDataModel>>{};

  for (final StampDataModel item in stamps) {
    final String key = item.album?.trim() ?? '';
    if (key.isEmpty) continue;
    grouped.putIfAbsent(key, () => <StampDataModel>[]).add(item);
  }

  final List<StampverseCollectionSummary> result = grouped.entries
      .map(
        (MapEntry<String, List<StampDataModel>> entry) =>
            StampverseCollectionSummary(name: entry.key, stamps: entry.value),
      )
      .toList(growable: false);

  result.sort(
    (StampverseCollectionSummary a, StampverseCollectionSummary b) =>
        b.latestDate.compareTo(a.latestDate),
  );
  return result;
}

String? resolveStampverseError(String? raw) {
  if (raw == null || raw.isEmpty) return null;

  if (raw == 'PASSWORD_MISMATCH') {
    return LocaleKey.stampverseRegisterPasswordMismatch.tr;
  }
  if (raw == 'CAMERA_PERMISSION_ERROR') {
    return LocaleKey.stampverseCameraPermissionError.tr;
  }

  return raw;
}
