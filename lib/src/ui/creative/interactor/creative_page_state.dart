import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_model.dart';
import 'package:stamp_camera/src/core/model/stamp_edit_template_model.dart';
import 'package:stamp_camera/src/ui/creative/interactor/creative_template_catalog.dart';

enum CreativeViewMode { templates, boards }

class CreativePageState extends Equatable {
  const CreativePageState({
    required this.boards,
    required this.templates,
    this.viewMode = CreativeViewMode.templates,
    this.selectedBoardIds = const <String>[],
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  factory CreativePageState.initial() {
    return CreativePageState(
      boards: const <StampEditBoard>[],
      templates: creativeTemplateCatalog,
    );
  }

  final List<StampEditBoard> boards;
  final List<StampEditTemplate> templates;
  final CreativeViewMode viewMode;
  final List<String> selectedBoardIds;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  CreativePageState copyWith({
    List<StampEditBoard>? boards,
    List<StampEditTemplate>? templates,
    CreativeViewMode? viewMode,
    List<String>? selectedBoardIds,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isInitialized,
  }) {
    return CreativePageState(
      boards: boards ?? this.boards,
      templates: templates ?? this.templates,
      viewMode: viewMode ?? this.viewMode,
      selectedBoardIds: selectedBoardIds ?? this.selectedBoardIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    boards,
    templates,
    viewMode,
    selectedBoardIds,
    isLoading,
    errorMessage,
    isInitialized,
  ];
}

const Object _sentinel = Object();
