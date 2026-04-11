import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:stamp_camera/src/ui/login/components/stampverse_login_view.dart';
import 'package:stamp_camera/src/ui/login/interactor/login_page_cubit.dart';
import 'package:stamp_camera/src/ui/login/interactor/login_page_state.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_view_helper.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<LoginPageCubit>(
        create: (_) => LoginPageCubit(),
        child: BlocBuilder<LoginPageCubit, LoginPageState>(
          builder: (BuildContext context, LoginPageState state) {
            final LoginPageCubit cubit = context.read<LoginPageCubit>();
            return StampverseLoginView(
              usernameController: _usernameController,
              passwordController: _passwordController,
              isLoading: state.isLoading,
              errorText: resolveStampverseError(state.errorMessage),
              onBack: () => Navigator.of(context).pop(),
              onSwitchToRegister: () {
                Navigator.of(context).pushNamed(CommonRouter.register);
              },
              onSubmit: () {
                cubit.login(
                  username: _usernameController.text,
                  password: _passwordController.text,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
