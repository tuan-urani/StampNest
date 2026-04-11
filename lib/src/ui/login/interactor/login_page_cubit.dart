import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/ui/login/interactor/login_page_state.dart';

class LoginPageCubit extends Cubit<LoginPageState> {
  LoginPageCubit() : super(const LoginPageState());

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(state.copyWith(errorMessage: null, isLoading: false));
  }
}
