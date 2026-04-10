import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseEditCreateView extends StatelessWidget {
  const StampverseEditCreateView({
    super.key,
    required this.nameController,
    required this.onBack,
    required this.onSave,
  });

  final TextEditingController nameController;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.stampversePrimaryText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        LocaleKey.stampverseEditCreateTitle.tr,
                        style: StampverseTextStyles.sectionTitle(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: <Widget>[
                    Text(
                      LocaleKey.stampverseEditCreateNameLabel.tr,
                      style: StampverseTextStyles.body(
                        color: AppColors.stampverseHeadingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.stampverseBorderSoft,
                        ),
                      ),
                      child: TextField(
                        controller: nameController,
                        maxLength: 40,
                        style: StampverseTextStyles.input(),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (nameController.text.trim().isEmpty) return;
                          onSave();
                        },
                        decoration: InputDecoration(
                          hintText:
                              LocaleKey.stampverseEditCreateNamePlaceholder.tr,
                          hintStyle: StampverseTextStyles.body(),
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nameController,
                  builder: (_, TextEditingValue value, _) {
                    final bool canSave = value.text.trim().isNotEmpty;

                    return SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: Material(
                        color: canSave
                            ? AppColors.colorF586AA6
                            : AppColors.colorF586AA6.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canSave ? onSave : null,
                          child: Center(
                            child: Text(
                              LocaleKey.stampverseEditCreateSave.tr,
                              style: StampverseTextStyles.button(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
