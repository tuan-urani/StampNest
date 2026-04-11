import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:stamp_camera/src/ui/register/components/stampverse_register_view.dart';
import 'package:stamp_camera/src/ui/register/interactor/register_page_cubit.dart';
import 'package:stamp_camera/src/ui/register/interactor/register_page_state.dart';
import 'package:stamp_camera/src/ui/routing/common_router.dart';
import 'package:stamp_camera/src/ui/stampverse_core/helpers/stampverse_view_helper.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: BlocProvider<RegisterPageCubit>(
        create: (_) => RegisterPageCubit(),
        child: BlocBuilder<RegisterPageCubit, RegisterPageState>(
          builder: (BuildContext context, RegisterPageState state) {
            final RegisterPageCubit cubit = context.read<RegisterPageCubit>();
            return StampverseRegisterView(
              usernameController: _usernameController,
              phoneController: _phoneController,
              passwordController: _passwordController,
              confirmController: _confirmController,
              isLoading: state.isLoading,
              isSuccess: state.isSuccess,
              errorText: resolveStampverseError(state.errorMessage),
              onBack: () => Navigator.of(context).pop(),
              onSwitchToLogin: () {
                Navigator.of(context).pushReplacementNamed(CommonRouter.login);
              },
              onSubmit: () {
                cubit.register(
                  username: _usernameController.text,
                  phone: _phoneController.text,
                  password: _passwordController.text,
                  confirmPassword: _confirmController.text,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
