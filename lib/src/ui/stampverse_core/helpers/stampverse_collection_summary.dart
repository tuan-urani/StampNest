import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class StampverseCollectionSummary {
  const StampverseCollectionSummary({required this.name, required this.stamps});

  final String name;
  final List<StampDataModel> stamps;

  DateTime get latestDate {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final StampDataModel item in stamps) {
      final DateTime candidate = item.parsedDate ?? latest;
      if (candidate.isAfter(latest)) {
        latest = candidate;
      }
    }
    return latest;
  }
}
