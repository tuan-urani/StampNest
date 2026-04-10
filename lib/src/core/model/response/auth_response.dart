class AuthResponse {
  const AuthResponse({
    required this.status,
    required this.token,
    required this.user,
    this.message,
  });

  final String status;
  final String token;
  final Map<String, dynamic> user;
  final String? message;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final dynamic userData = json['user'];
    return AuthResponse(
      status: json['status']?.toString() ?? 'error',
      token: json['token']?.toString() ?? '',
      user: userData is Map<String, dynamic> ? userData : <String, dynamic>{},
      message: json['message']?.toString(),
    );
  }
}
