import 'package:equatable/equatable.dart';

class SaveStampState extends Equatable {
  const SaveStampState({
    required this.collections,
    this.isSaving = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory SaveStampState.initial() {
    return const SaveStampState(collections: <String>[]);
  }

  final List<String> collections;
  final bool isSaving;
  final String? errorMessage;
  final bool isInitialized;

  SaveStampState copyWith({
    List<String>? collections,
    bool? isSaving,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return SaveStampState(
      collections: collections ?? this.collections,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    collections,
    isSaving,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
