import 'package:equatable/equatable.dart';

class RegisterPageState extends Equatable {
  const RegisterPageState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  RegisterPageState copyWith({
    bool? isLoading,
    bool? isSuccess,
    Object? errorMessage = _sentinel,
  }) {
    return RegisterPageState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, isSuccess, errorMessage];
}

const Object _sentinel = Object();
