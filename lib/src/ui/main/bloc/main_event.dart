import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object?> get props => [];
}

class MainInitialized extends MainEvent {
  const MainInitialized();
}

class OnChangeTabEvent extends MainEvent {
  final BottomNavigationPage page;

  const OnChangeTabEvent(this.page);

  @override
  List<Object?> get props => [page];
}
