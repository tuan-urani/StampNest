import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_primary_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseLoginView extends StatelessWidget {
  const StampverseLoginView({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
    required this.onSwitchToRegister,
    this.onBack,
    this.isLoading = false,
    this.errorText,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToRegister;
  final VoidCallback? onBack;
  final bool isLoading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: StampverseIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: onBack,
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKey.stampverseLoginTitle.tr,
                      style: StampverseTextStyles.heroTitle(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKey.stampverseLoginSubtitle.tr,
                      style: StampverseTextStyles.body(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _AuthInput(
                      controller: usernameController,
                      hint: LocaleKey.stampverseLoginUsernamePlaceholder.tr,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _AuthInput(
                      controller: passwordController,
                      hint: LocaleKey.stampverseLoginPasswordPlaceholder.tr,
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    if (errorText != null && errorText!.isNotEmpty) ...<Widget>[
                      Text(
                        errorText!,
                        textAlign: TextAlign.center,
                        style: StampverseTextStyles.caption(
                          color: AppColors.stampverseDanger,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    StampversePrimaryButton(
                      label: isLoading
                          ? LocaleKey.stampverseLoginLoading.tr
                          : LocaleKey.stampverseLoginSubmit.tr,
                      icon: Icons.arrow_forward_rounded,
                      enabled: !isLoading,
                      onTap: onSubmit,
                    ),
                    const Spacer(),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: <Widget>[
                        Text(
                          LocaleKey.stampverseLoginNoAccount.tr,
                          style: StampverseTextStyles.body(),
                        ),
                        GestureDetector(
                          onTap: onSwitchToRegister,
                          child: Text(
                            LocaleKey.stampverseLoginSwitchRegister.tr,
                            style: StampverseTextStyles.body(
                              color: AppColors.stampversePrimaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatefulWidget {
  const _AuthInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;

  @override
  State<_AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<_AuthInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final bool useObscure = widget.obscureText ? _obscure : false;

    return TextField(
      controller: widget.controller,
      obscureText: useObscure,
      style: StampverseTextStyles.input(),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: StampverseTextStyles.input(
          color: AppColors.stampverseMutedText,
        ),
        prefixIcon: Icon(
          widget.icon,
          color: AppColors.stampverseMutedText,
          size: 20,
        ),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  useObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.stampverseMutedText,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.stampverseBorderSoft,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.stampverseBorderSoft,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.stampversePrimaryText,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
