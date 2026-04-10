import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';
import 'package:stamp_camera/src/utils/app_styles.dart';

class StampverseSaveView extends StatefulWidget {
  const StampverseSaveView({
    super.key,
    required this.imageUrl,
    required this.shapeType,
    required this.nameController,
    required this.collectionController,
    required this.collections,
    required this.defaultCollection,
    required this.onBack,
    required this.onSave,
  });

  final String imageUrl;
  final StampShapeType shapeType;
  final TextEditingController nameController;
  final TextEditingController collectionController;
  final List<String> collections;
  final String defaultCollection;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  State<StampverseSaveView> createState() => _StampverseSaveViewState();
}

class _StampverseSaveViewState extends State<StampverseSaveView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _stampScale;
  late final Animation<double> _stampFade;
  late final Animation<double> _metaFade;
  final List<String> _draftCollections = <String>[];

  @override
  void initState() {
    super.initState();

    if (widget.nameController.text.trim().isEmpty) {
      widget.nameController.text = _generateStampCode();
    }

    _syncCollectionValue();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _stampScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _stampFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );
    _metaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StampverseSaveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections ||
        oldWidget.defaultCollection != widget.defaultCollection) {
      _syncCollectionValue();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generateStampCode() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random random = Random();
    final String suffix = List<String>.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();

    return 'STAMP-$suffix';
  }

  List<String> _collectionOptions() {
    final LinkedHashSet<String> values = LinkedHashSet<String>();
    final String defaultValue = widget.defaultCollection.trim();
    if (defaultValue.isNotEmpty) {
      values.add(defaultValue);
    }

    final Set<String> legacyFallbackValues = <String>{
      LocaleKey.stampverseSaveInbox.tr.trim().toLowerCase(),
      'inbox',
      'hộp thư',
    };

    for (final String item in widget.collections) {
      final String name = item.trim();
      if (name.isEmpty) continue;
      if (legacyFallbackValues.contains(name.toLowerCase())) continue;
      values.add(name);
    }

    for (final String item in _draftCollections) {
      final String name = item.trim();
      if (name.isEmpty) continue;
      if (legacyFallbackValues.contains(name.toLowerCase())) continue;
      values.add(name);
    }
    return values.toList(growable: false);
  }

  Future<void> _createCollection() async {
    final TextEditingController controller = TextEditingController();
    final String? createdName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.stampverseSurface,
          title: Text(
            LocaleKey.stampverseSaveCollectionCreateTitle.tr,
            style: AppStyles.bodyLarge(
              color: AppColors.stampverseHeadingText,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
            style: AppStyles.bodyLarge(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: LocaleKey.stampverseSaveCollectionCreatePlaceholder.tr,
              hintStyle: AppStyles.bodyLarge(
                color: AppColors.colorB7B7B7,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.stampverseBorderSoft,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.stampverseBorderSoft,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.colorF586AA6,
                  width: 1.2,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                LocaleKey.widgetCancel.tr,
                style: AppStyles.bodyMedium(
                  color: AppColors.stampverseMutedText,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(
                LocaleKey.widgetConfirm.tr,
                style: AppStyles.bodyMedium(
                  color: AppColors.colorF586AA6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final String normalized = createdName?.trim() ?? '';
    if (!mounted || normalized.isEmpty) return;

    final List<String> allOptions = _collectionOptions();
    final bool alreadyExists = allOptions.any(
      (String item) => item.toLowerCase() == normalized.toLowerCase(),
    );

    if (!alreadyExists) {
      setState(() {
        _draftCollections.add(normalized);
      });
    }

    widget.collectionController.text = normalized;
    widget.collectionController.selection = TextSelection.collapsed(
      offset: normalized.length,
    );
  }

  void _syncCollectionValue() {
    final List<String> options = _collectionOptions();
    if (options.isEmpty) return;

    final String current = widget.collectionController.text.trim();
    if (current.isEmpty) return;

    String? matchedOption;
    for (final String option in options) {
      if (option.toLowerCase() == current.toLowerCase()) {
        matchedOption = option;
        break;
      }
    }
    if (matchedOption == null || matchedOption == current) return;

    widget.collectionController.text = matchedOption;
    widget.collectionController.selection = TextSelection.collapsed(
      offset: matchedOption.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> collections = _collectionOptions();
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardInset > 0;

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, Widget? child) {
            final Widget body = Column(
              children: <Widget>[
                Text(
                  LocaleKey.stampverseCameraTitle.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.h4(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ).copyWith(height: 1.1),
                ),
                const SizedBox(height: 32),
                Transform.scale(
                  scale: _stampScale.value,
                  child: Opacity(
                    opacity: _stampFade.value,
                    child: StampverseStamp(
                      imageUrl: widget.imageUrl,
                      shapeType: widget.shapeType,
                      width: 146,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _metaFade.value,
                  child: _SaveInputField(
                    label: LocaleKey.stampverseSaveNameHint.tr,
                    hint: LocaleKey.stampverseSaveNamePlaceholder.tr,
                    controller: widget.nameController,
                    textInputAction: TextInputAction.done,
                    capitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: _metaFade.value,
                  child: _CollectionInputField(
                    label: LocaleKey.stampverseSaveCollectionLabel.tr,
                    hint: LocaleKey.stampverseSaveCollectionPlaceholder.tr,
                    options: collections,
                    controller: widget.collectionController,
                    onCreateCollection: _createCollection,
                  ),
                ),
                const SizedBox(height: 20),
                if (!isKeyboardVisible)
                  Opacity(
                    opacity: _metaFade.value,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _BottomActionButton(
                            label: LocaleKey.stampverseSaveBackButton.tr,
                            onTap: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BottomActionButton(
                            label: LocaleKey.stampverseSaveTopAction.tr,
                            onTap: widget.onSave,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 6),
                const SizedBox(height: 4),
              ],
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + keyboardInset),
              child: body,
            );
          },
        ),
      ),
    );
  }
}

class _SaveInputField extends StatelessWidget {
  const _SaveInputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.textInputAction,
    required this.capitalization,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppStyles.bodyLarge(
            color: AppColors.colorF586AA6,
            fontWeight: FontWeight.w700,
          ).copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: textInputAction,
          textCapitalization: capitalization,
          style: AppStyles.bodyLarge(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ).copyWith(height: 1.2),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyLarge(
              color: AppColors.colorB7B7B7,
              fontWeight: FontWeight.w500,
            ).copyWith(height: 1.2),
            isDense: true,
            filled: true,
            fillColor: AppColors.white.withValues(alpha: 0.72),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.stampverseBorderSoft,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.stampverseBorderSoft,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.colorF586AA6,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionInputField extends StatelessWidget {
  const _CollectionInputField({
    required this.label,
    required this.hint,
    required this.options,
    required this.controller,
    required this.onCreateCollection,
  });

  final String label;
  final String hint;
  final List<String> options;
  final TextEditingController controller;
  final Future<void> Function() onCreateCollection;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppStyles.bodyLarge(
      color: AppColors.black,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppStyles.bodyLarge(
            color: AppColors.colorF586AA6,
            fontWeight: FontWeight.w700,
          ).copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: TextInputAction.done,
          style: valueStyle.copyWith(height: 1.2),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyLarge(
              color: AppColors.colorB7B7B7,
              fontWeight: FontWeight.w500,
            ).copyWith(height: 1.2),
            isDense: true,
            filled: true,
            fillColor: AppColors.white.withValues(alpha: 0.72),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.stampverseBorderSoft,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.stampverseBorderSoft,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.colorF586AA6,
                width: 1.4,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onCreateCollection,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.colorF586AA6,
              ),
              tooltip: LocaleKey.stampverseSaveCollectionCreateAction.tr,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                LocaleKey.stampverseSaveCollectionQuickPick.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.stampverseMutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: onCreateCollection,
              child: Text(
                LocaleKey.stampverseSaveCollectionCreateAction.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.colorF586AA6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (options.isNotEmpty)
          SizedBox(
            height: 40,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, TextEditingValue value, Widget? child) {
                final String current = value.text.trim().toLowerCase();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, int index) {
                    final String option = options[index];
                    final bool selected = current == option.toLowerCase();
                    return _CollectionOptionChip(
                      label: option,
                      selected: selected,
                      onTap: () {
                        controller.text = option;
                        controller.selection = TextSelection.collapsed(
                          offset: option.length,
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        else
          Text(
            LocaleKey.stampverseSaveCollectionCreateHint.tr,
            style: AppStyles.bodySmall(
              color: AppColors.stampverseMutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _CollectionOptionChip extends StatelessWidget {
  const _CollectionOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? AppColors.colorF586AA6.withValues(alpha: 0.15)
                : AppColors.white.withValues(alpha: 0.72),
            border: Border.all(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampverseBorderSoft,
            ),
          ),
          child: Text(
            label,
            style: AppStyles.bodySmall(
              color: selected
                  ? AppColors.colorF586AA6
                  : AppColors.stampversePrimaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color background = isPrimary
        ? AppColors.colorF586AA6
        : AppColors.white.withValues(alpha: 0.72);
    final Color textColor = isPrimary
        ? AppColors.white
        : AppColors.colorF586AA6;
    final Color border = isPrimary
        ? AppColors.colorF586AA6
        : AppColors.stampverseBorderSoft;

    return SizedBox(
      height: 54,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                label,
                style: AppStyles.buttonLarge(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
