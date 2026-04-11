import 'package:equatable/equatable.dart';
import 'package:stamp_camera/src/enums/bottom_navigation_page.dart';

class MainState extends Equatable {
  final BottomNavigationPage currentPage;

  const MainState({this.currentPage = BottomNavigationPage.stamp});

  MainState copyWith({BottomNavigationPage? currentPage}) {
    return MainState(currentPage: currentPage ?? this.currentPage);
  }

  @override
  List<Object?> get props => [currentPage];
}
