class AuthRegisterRequest {
  const AuthRegisterRequest({
    required this.username,
    required this.phone,
    required this.password,
  });

  final String username;
  final String phone;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'phone': phone,
      'password': password,
    };
  }
}
