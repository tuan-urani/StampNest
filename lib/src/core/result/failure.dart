import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[message, statusCode];
}
