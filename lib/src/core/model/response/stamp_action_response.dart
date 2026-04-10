class StampActionResponse {
  const StampActionResponse({required this.status, this.message});

  final String status;
  final String? message;

  factory StampActionResponse.fromJson(Map<String, dynamic> json) {
    return StampActionResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
    );
  }
}
