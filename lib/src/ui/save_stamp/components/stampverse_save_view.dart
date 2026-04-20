import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/save_stamp/helpers/stampverse_save_stamp_export.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse_core/components/stampverse_stamp.dart';
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
  final void Function(
    double rotationRadians,
    double previewBaseWidth,
    double previewBoundsWidth,
    double previewBoundsHeight,
  )
  onSave;

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
  double _previewRotationRadians = 0;
  double _rotationAtScaleStart = 0;

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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 26,
            vertical: 24,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.colorF586AA6.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    size: 18,
                    color: AppColors.colorF586AA6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  LocaleKey.stampverseSaveCollectionCreateTitle.tr,
                  style: AppStyles.bodyLarge(
                    color: AppColors.stampverseHeadingText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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

  void _onPreviewScaleStart(ScaleStartDetails _) {
    _rotationAtScaleStart = _previewRotationRadians;
  }

  void _onPreviewScaleUpdate(ScaleUpdateDetails details) {
    final double nextRotation = _normalizeRotation(
      _rotationAtScaleStart + details.rotation,
    );
    if (nextRotation == _previewRotationRadians) {
      return;
    }
    setState(() {
      _previewRotationRadians = nextRotation;
    });
  }

  double _normalizeRotation(double value) {
    if (!value.isFinite) return 0;
    const double fullTurn = pi * 2;
    double normalized = value % fullTurn;
    if (normalized > pi) {
      normalized -= fullTurn;
    } else if (normalized < -pi) {
      normalized += fullTurn;
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 24;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final List<String> collections = _collectionOptions();
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final bool isKeyboardVisible = keyboardInset > 0;
    final double previewViewportWidth = max(
      0,
      mediaQuery.size.width - (horizontalPadding * 2),
    );
    final double previewViewportHeight = max(
      0,
      mediaQuery.size.height - mediaQuery.padding.vertical,
    );
    final double previewBaseWidth = resolveSaveStampPreviewBaseWidth(
      viewportSize: Size(previewViewportWidth, previewViewportHeight),
      shapeType: widget.shapeType,
    );
    final Size previewBaseSize = resolveSaveStampPreviewSize(
      shapeType: widget.shapeType,
      baseWidth: previewBaseWidth,
    );
    final Size rotatedPreviewBounds = resolveSaveStampRotatedBounds(
      size: previewBaseSize,
      rotationRadians: _previewRotationRadians,
    );
    final double previewBoundsWidth =
        rotatedPreviewBounds.width.isFinite && rotatedPreviewBounds.width > 0
        ? rotatedPreviewBounds.width
        : previewBaseSize.width;
    final double previewBoundsHeight =
        rotatedPreviewBounds.height.isFinite && rotatedPreviewBounds.height > 0
        ? rotatedPreviewBounds.height
        : previewBaseSize.height;

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, Widget? child) {
            final Widget body = Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StampverseIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: widget.onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LocaleKey.stampverseCameraTitle.tr,
                        textAlign: TextAlign.center,
                        style: AppStyles.h4(
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                        ).copyWith(height: 1.1),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
                const SizedBox(height: 22),
                Transform.scale(
                  scale: _stampScale.value,
                  child: Opacity(
                    opacity: _stampFade.value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onScaleStart: _onPreviewScaleStart,
                      onScaleUpdate: _onPreviewScaleUpdate,
                      child: _SaveStampPreview(
                        imageUrl: widget.imageUrl,
                        shapeType: widget.shapeType,
                        width: previewBaseSize.width,
                        boundsWidth: previewBoundsWidth,
                        boundsHeight: previewBoundsHeight,
                        rotationRadians: _previewRotationRadians,
                      ),
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
                            onTap: () => widget.onSave(
                              _previewRotationRadians,
                              previewBaseWidth,
                              previewBoundsWidth,
                              previewBoundsHeight,
                            ),
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
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24 + keyboardInset,
              ),
              child: body,
            );
          },
        ),
      ),
    );
  }
}

class _SaveStampPreview extends StatelessWidget {
  const _SaveStampPreview({
    required this.imageUrl,
    required this.shapeType,
    required this.width,
    required this.boundsWidth,
    required this.boundsHeight,
    required this.rotationRadians,
  });

  final String imageUrl;
  final StampShapeType shapeType;
  final double width;
  final double boundsWidth;
  final double boundsHeight;
  final double rotationRadians;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boundsWidth,
      height: boundsHeight,
      child: Center(
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: shapeType.aspectRatio,
            child: Center(
              child: Transform.rotate(
                angle: rotationRadians,
                child: StampverseStamp(
                  imageUrl: imageUrl,
                  shapeType: shapeType,
                  showShadow: false,
                ),
              ),
            ),
          ),
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
    final List<String> normalizedOptions = options
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final TextStyle valueStyle = AppStyles.bodyLarge(
      color: AppColors.black,
      fontWeight: FontWeight.w700,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, TextEditingValue value, _) {
        final String current = value.text.trim().toLowerCase();
        String? selectedValue;
        for (final String option in normalizedOptions) {
          if (option.toLowerCase() == current) {
            selectedValue = option;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppStyles.bodyLarge(
                      color: AppColors.colorF586AA6,
                      fontWeight: FontWeight.w700,
                    ).copyWith(height: 1.2),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: LocaleKey.stampverseSaveCollectionCreateAction.tr,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.stampverseBorderSoft,
                        ),
                      ),
                      child: Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await onCreateCollection();
                          },
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.colorF586AA6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputDecorator(
              isEmpty: selectedValue == null,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.72),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: AppColors.stampverseSurface,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.colorF586AA6,
                  ),
                  style: valueStyle.copyWith(height: 1.2),
                  hint: Text(
                    hint,
                    style: AppStyles.bodyLarge(
                      color: AppColors.colorB7B7B7,
                      fontWeight: FontWeight.w500,
                    ).copyWith(height: 1.2),
                  ),
                  items: normalizedOptions
                      .map(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            overflow: TextOverflow.ellipsis,
                            style: valueStyle.copyWith(height: 1.2),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: normalizedOptions.isEmpty
                      ? null
                      : (String? selected) {
                          final String nextValue = selected?.trim() ?? '';
                          controller.text = nextValue;
                          controller.selection = TextSelection.collapsed(
                            offset: nextValue.length,
                          );
                        },
                ),
              ),
            ),
            if (normalizedOptions.isEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                LocaleKey.stampverseSaveCollectionCreateHint.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.stampverseMutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
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
