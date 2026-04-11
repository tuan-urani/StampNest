import 'package:equatable/equatable.dart';

class LoginPageState extends Equatable {
  const LoginPageState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  LoginPageState copyWith({bool? isLoading, Object? errorMessage = _sentinel}) {
    return LoginPageState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, errorMessage];
}

const Object _sentinel = Object();
