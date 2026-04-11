import 'package:equatable/equatable.dart';

class SettingsPageState extends Equatable {
  const SettingsPageState({
    this.stampsCount = 0,
    this.collectionsCount = 0,
    this.isRefreshing = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  final int stampsCount;
  final int collectionsCount;
  final bool isRefreshing;
  final String? errorMessage;
  final bool isInitialized;

  SettingsPageState copyWith({
    int? stampsCount,
    int? collectionsCount,
    bool? isRefreshing,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return SettingsPageState(
      stampsCount: stampsCount ?? this.stampsCount,
      collectionsCount: collectionsCount ?? this.collectionsCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    stampsCount,
    collectionsCount,
    isRefreshing,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
