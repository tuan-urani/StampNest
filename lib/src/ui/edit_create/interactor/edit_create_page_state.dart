import 'package:equatable/equatable.dart';

class EditCreatePageState extends Equatable {
  const EditCreatePageState({this.isSaving = false, this.errorMessage});

  EditCreatePageState copyWith({
    bool? isSaving,
    Object? errorMessage = _sentinel,
  }) {
    return EditCreatePageState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  final bool isSaving;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[isSaving, errorMessage];
}

const Object _sentinel = Object();
