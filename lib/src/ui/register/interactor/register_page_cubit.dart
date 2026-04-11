import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stamp_camera/src/ui/register/interactor/register_page_state.dart';

class RegisterPageCubit extends Cubit<RegisterPageState> {
  RegisterPageCubit() : super(const RegisterPageState());

  Future<void> register({
    required String username,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    emit(
      state.copyWith(errorMessage: null, isLoading: false, isSuccess: false),
    );
  }
}
