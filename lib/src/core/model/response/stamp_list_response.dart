import 'package:stamp_camera/src/core/model/stamp_data_model.dart';

class StampListResponse {
  const StampListResponse({
    required this.status,
    required this.data,
    this.message,
  });

  final String status;
  final List<StampDataModel> data;
  final String? message;

  factory StampListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic payload = json['data'];
    final List<dynamic> list = payload is List<dynamic> ? payload : <dynamic>[];

    return StampListResponse(
      status: json['status']?.toString() ?? 'error',
      data: list
          .whereType<Map<String, dynamic>>()
          .map(StampDataModel.fromJson)
          .toList(growable: false),
      message: json['message']?.toString(),
    );
  }
}
