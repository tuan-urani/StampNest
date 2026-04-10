import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/locale/locale_key.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_icon_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_primary_button.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp_shape.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_text_styles.dart';
import 'package:stamp_camera/src/utils/app_assets.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

const double _kStampGuideWidthFactor = 0.58;
const double _kStampGuideMaxHeightFactor = 0.46;
const double _kStampGuideVerticalAnchor = 0.44;

ui.Rect _resolveGuideRectInViewport({
  required ui.Size viewportSize,
  required StampShapeType shapeType,
}) {
  final double maxWidth = viewportSize.width * _kStampGuideWidthFactor;
  final double maxHeight = viewportSize.height * _kStampGuideMaxHeightFactor;

  double guideWidth = maxWidth;
  double guideHeight = guideWidth / shapeType.aspectRatio;
  if (guideHeight > maxHeight) {
    guideHeight = maxHeight;
    guideWidth = guideHeight * shapeType.aspectRatio;
  }

  final double left = (viewportSize.width - guideWidth) / 2;
  final double anchorCenterY = viewportSize.height * _kStampGuideVerticalAnchor;
  final double minTop = viewportSize.height * 0.12;
  final double maxTop = viewportSize.height * 0.70 - guideHeight;
  final double top = (anchorCenterY - (guideHeight / 2)).clamp(minTop, maxTop);

  return ui.Rect.fromLTWH(left, top, guideWidth, guideHeight);
}

ui.Rect _stampApertureNormalizedInPreview({
  required ui.Size previewSize,
  required StampShapeType shapeType,
}) {
  final ui.Rect aperture = _resolveGuideRectInViewport(
    viewportSize: previewSize,
    shapeType: shapeType,
  );
  return ui.Rect.fromLTWH(
    aperture.left / previewSize.width,
    aperture.top / previewSize.height,
    aperture.width / previewSize.width,
    aperture.height / previewSize.height,
  );
}

class StampverseCameraView extends StatefulWidget {
  const StampverseCameraView({
    super.key,
    required this.onBack,
    required this.onCaptureLiveCamera,
    required this.onConfirmCrop,
    required this.onReset,
    required this.selectedShape,
    required this.onShapeChanged,
    this.draftImage,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onCaptureLiveCamera;
  final ValueChanged<String> onConfirmCrop;
  final VoidCallback onReset;
  final StampShapeType selectedShape;
  final ValueChanged<StampShapeType> onShapeChanged;
  final String? draftImage;

  @override
  State<StampverseCameraView> createState() => _StampverseCameraViewState();
}

class _StampverseCameraViewState extends State<StampverseCameraView> {
  final GlobalKey<_CropPreviewState> _cropPreviewKey =
      GlobalKey<_CropPreviewState>();
  bool _isApplyingCrop = false;

  Future<void> _handleConfirmCrop() async {
    if (_isApplyingCrop) return;

    final String? draftImage = widget.draftImage;
    if (draftImage == null || draftImage.isEmpty) return;

    setState(() {
      _isApplyingCrop = true;
    });

    final String? croppedImage = await _cropPreviewKey.currentState
        ?.exportCroppedImageDataUrl();
    if (!mounted) return;

    widget.onConfirmCrop(croppedImage ?? draftImage);

    if (!mounted) return;
    setState(() {
      _isApplyingCrop = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? draftImage = widget.draftImage;
    final bool hasDraft = draftImage != null && draftImage.isNotEmpty;

    if (!hasDraft) {
      return ColoredBox(
        color: AppColors.black,
        child: _LiveCameraCaptureView(
          selectedShape: widget.selectedShape,
          onShapeChanged: widget.onShapeChanged,
          onCapture: widget.onCaptureLiveCamera,
          onBack: widget.onBack,
        ),
      );
    }

    return ColoredBox(
      color: AppColors.stampverseBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: <Widget>[
                  StampverseIconButton(
                    icon: Icons.close_rounded,
                    onTap: widget.onBack,
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _CropPreview(
                key: _cropPreviewKey,
                imageUrl: draftImage,
                shapeType: widget.selectedShape,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _CameraShapeSelector(
                selectedShape: widget.selectedShape,
                onShapeChanged: widget.onShapeChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Row(
                children: <Widget>[
                  StampverseIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: widget.onReset,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StampversePrimaryButton(
                      label: LocaleKey.stampverseCameraCrop.tr,
                      icon: Icons.check_rounded,
                      onTap: _handleConfirmCrop,
                      enabled: !_isApplyingCrop,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCameraCaptureView extends StatefulWidget {
  const _LiveCameraCaptureView({
    required this.selectedShape,
    required this.onShapeChanged,
    required this.onCapture,
    required this.onBack,
  });

  final StampShapeType selectedShape;
  final ValueChanged<StampShapeType> onShapeChanged;
  final ValueChanged<String> onCapture;
  final VoidCallback onBack;

  @override
  State<_LiveCameraCaptureView> createState() => _LiveCameraCaptureViewState();
}

class _LiveCameraCaptureViewState extends State<_LiveCameraCaptureView>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = <CameraDescription>[];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoomLevel = 1;
  double _baseZoomLevel = 1;
  int _activePointers = 0;
  ui.Size _previewViewportSize = const ui.Size(1080, 1920);
  String? _capturedFrameDataUrl;
  String? _capturedStampImageUrl;
  Uint8List? _capturedStampImageBytes;
  final AudioPlayer _captureSoundPlayer = AudioPlayer();
  late final AnimationController _cutController;

  @override
  void initState() {
    super.initState();
    _cutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _cutController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _initLiveCamera();
  }

  @override
  void dispose() {
    _cutController.dispose();
    unawaited(_captureSoundPlayer.dispose());
    _disposeController();
    super.dispose();
  }

  Future<void> _initLiveCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = LocaleKey.stampverseCameraPermissionError.tr;
        });
        return;
      }

      _availableCameras = cameras;
      _selectedCameraIndex = _preferredBackCameraIndex(cameras);
      await _startCamera(cameras[_selectedCameraIndex]);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = LocaleKey.stampverseCameraPermissionError.tr;
      });
    }
  }

  int _preferredBackCameraIndex(List<CameraDescription> cameras) {
    final int backIndex = cameras.indexWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.back,
    );
    return backIndex >= 0 ? backIndex : 0;
  }

  Future<void> _startCamera(CameraDescription camera) async {
    await _disposeController();

    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _zoomLevel = _minZoom.clamp(1.0, _maxZoom);
      await controller.setZoomLevel(_zoomLevel);

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = LocaleKey.stampverseCameraPermissionError.tr;
      });
    }
  }

  Future<void> _disposeController() async {
    final CameraController? controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isInitializing) return;

    setState(() {
      _isInitializing = true;
      _error = null;
      _selectedCameraIndex =
          (_selectedCameraIndex + 1) % _availableCameras.length;
    });

    await _startCamera(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _setZoom(double zoom) async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final double target = zoom.clamp(_minZoom, _maxZoom);
    await controller.setZoomLevel(target);
    if (!mounted) return;
    setState(() {
      _zoomLevel = target;
    });
  }

  void _onScaleStart(ScaleStartDetails _) {
    _baseZoomLevel = _zoomLevel;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_activePointers < 2) return;
    final double nextZoom = (_baseZoomLevel * details.scale).clamp(
      _minZoom,
      _maxZoom,
    );
    if ((nextZoom - _zoomLevel).abs() < 0.02) return;
    await _setZoom(nextZoom);
  }

  Future<void> _capture() async {
    final CameraController? controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _isInitializing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      unawaited(_playCaptureSound());

      final XFile file = await controller.takePicture();
      try {
        await controller.pausePreview();
      } catch (_) {}
      final Uint8List bytes = await file.readAsBytes();
      final String dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final String outputDataUrl =
          await _cropCapturedToSelectedStamp(bytes, widget.selectedShape) ??
          dataUrl;
      final Uint8List? outputBytes = _tryDecodeDataUrl(outputDataUrl);
      if (outputBytes != null && mounted) {
        await precacheImage(MemoryImage(outputBytes), context);
      }

      if (!mounted) return;
      setState(() {
        _capturedFrameDataUrl = dataUrl;
        _capturedStampImageUrl = outputDataUrl;
        _capturedStampImageBytes = outputBytes;
      });

      await _cutController.forward(from: 0);

      if (!mounted) return;
      widget.onCapture(outputDataUrl);
    } catch (_) {
      try {
        await controller.resumePreview();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _error = LocaleKey.stampverseCameraPermissionError.tr;
      });
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _playCaptureSound() async {
    try {
      await _captureSoundPlayer.stop();
      await _captureSoundPlayer.play(
        AssetSource(AppAssets.audioTakePicSoundMp3.replaceFirst('assets/', '')),
      );
    } catch (_) {}
  }

  Uint8List? _tryDecodeDataUrl(String value) {
    if (!value.startsWith('data:image')) return null;
    final int commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex >= value.length - 1) return null;
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Future<String?> _cropCapturedToSelectedStamp(
    Uint8List bytes,
    StampShapeType shapeType,
  ) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image sourceImage = frameInfo.image;
      final ui.Rect normalized = _stampApertureNormalizedInPreview(
        previewSize: _previewViewportSize,
        shapeType: shapeType,
      );

      final double left = (sourceImage.width * normalized.left).clamp(
        0,
        sourceImage.width.toDouble(),
      );
      final double top = (sourceImage.height * normalized.top).clamp(
        0,
        sourceImage.height.toDouble(),
      );
      final double maxRight = sourceImage.width.toDouble();
      final double maxBottom = sourceImage.height.toDouble();
      final double right = (sourceImage.width * normalized.right).clamp(
        left + 1,
        maxRight,
      );
      final double bottom = (sourceImage.height * normalized.bottom).clamp(
        top + 1,
        maxBottom,
      );

      final ui.Rect sourceRect = ui.Rect.fromLTRB(left, top, right, bottom);
      final int targetWidth = sourceRect.width.round().clamp(1, 4096);
      final int targetHeight = sourceRect.height.round().clamp(1, 4096);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        sourceImage,
        sourceRect,
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint(),
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(
        targetWidth,
        targetHeight,
      );
      final ByteData? byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      croppedImage.dispose();
      sourceImage.dispose();
      codec.dispose();

      if (byteData == null) return null;
      final String encoded = base64Encode(byteData.buffer.asUint8List());
      return 'data:image/png;base64,$encoded';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _controller;
    final bool hasCamera = controller != null && controller.value.isInitialized;
    final String? capturedFrame = _capturedFrameDataUrl;
    final String? capturedStampImage = _capturedStampImageUrl ?? capturedFrame;
    final Uint8List? capturedStampImageBytes = _capturedStampImageBytes;
    final double topInset = MediaQuery.paddingOf(context).top;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool canSwitchCamera =
        _availableCameras.length > 1 && !_isInitializing;

    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        _previewViewportSize = ui.Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Listener(
              onPointerDown: (_) => _activePointers += 1,
              onPointerUp: (_) {
                if (_activePointers > 0) {
                  _activePointers -= 1;
                }
              },
              onPointerCancel: (_) {
                if (_activePointers > 0) {
                  _activePointers -= 1;
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (hasCamera)
                      CameraPreview(controller)
                    else
                      const ColoredBox(color: AppColors.stampverseSurface),
                    IgnorePointer(
                      child: _StampGuideOverlay(
                        shapeType: widget.selectedShape,
                      ),
                    ),
                    if (capturedFrame != null && capturedStampImage != null)
                      _CutStampAnimationOverlay(
                        stampImageUrl: capturedStampImage,
                        stampImageBytes: capturedStampImageBytes,
                        shapeType: widget.selectedShape,
                        progress: _cutController.value,
                      ),
                    if (_isInitializing)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.stampversePrimaryText,
                        ),
                      ),
                    if (_error != null && _error!.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: StampverseTextStyles.caption(
                                  color: AppColors.stampverseDanger,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StampversePrimaryButton(
                                label: LocaleKey.stampverseCameraRetry.tr,
                                onTap: _initLiveCamera,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: topInset + 12,
              left: 12,
              child: StampverseIconButton(
                icon: Icons.close_rounded,
                onTap: widget.onBack,
              ),
            ),
            Positioned(
              top: topInset + 12,
              right: 12,
              child: StampverseIconButton(
                icon: Icons.cameraswitch_outlined,
                onTap: canSwitchCamera ? _switchCamera : null,
                iconColor: canSwitchCamera
                    ? AppColors.stampversePrimaryText
                    : AppColors.stampversePrimaryText.withValues(alpha: 0.4),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomInset + 24,
              child: Column(
                children: <Widget>[
                  _CameraShapeSelector(
                    selectedShape: widget.selectedShape,
                    onShapeChanged: widget.onShapeChanged,
                  ),
                  const SizedBox(height: 12),
                  _CameraShutterButton(
                    onTap: _capture,
                    isCapturing: _isCapturing,
                    enabled: hasCamera && !_isInitializing,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CameraShutterButton extends StatelessWidget {
  const _CameraShutterButton({
    required this.onTap,
    required this.isCapturing,
    required this.enabled,
  });

  final VoidCallback onTap;
  final bool isCapturing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final double outerAlpha = enabled ? 0.62 : 0.36;
    final double innerAlpha = enabled ? 0.9 : 0.7;

    return SizedBox(
      width: 78,
      height: 78,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled && !isCapturing ? onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: outerAlpha),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.88),
                width: 2.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: innerAlpha),
                  border: Border.all(
                    color: AppColors.colorCDCDCD.withValues(alpha: 0.72),
                  ),
                ),
                child: isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.stampversePrimaryText,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraShapeSelector extends StatelessWidget {
  const _CameraShapeSelector({
    required this.selectedShape,
    required this.onShapeChanged,
  });

  final StampShapeType selectedShape;
  final ValueChanged<StampShapeType> onShapeChanged;

  @override
  Widget build(BuildContext context) {
    const List<StampShapeType> options = <StampShapeType>[
      StampShapeType.scallop,
      StampShapeType.circle,
      StampShapeType.square,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options
          .map((StampShapeType option) {
            final bool active = option == selectedShape;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => onShapeChanged(option),
                child: _ShapeOptionIcon(shapeType: option, active: active),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ShapeOptionIcon extends StatelessWidget {
  const _ShapeOptionIcon({required this.shapeType, required this.active});

  final StampShapeType shapeType;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: active ? 0.34 : 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.42),
          width: active ? 1.6 : 1.1,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: _ShapeGlyphPainter(shapeType: shapeType, active: active),
          ),
        ),
      ),
    );
  }
}

class _ShapeGlyphPainter extends CustomPainter {
  const _ShapeGlyphPainter({required this.shapeType, required this.active});

  final StampShapeType shapeType;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final Path path = buildStampShapePath(rect: rect, shapeType: shapeType);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2.2 : 1.8
      ..color = AppColors.white;

    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ShapeGlyphPainter oldDelegate) {
    return oldDelegate.shapeType != shapeType || oldDelegate.active != active;
  }
}

class _CutStampAnimationOverlay extends StatelessWidget {
  const _CutStampAnimationOverlay({
    required this.stampImageUrl,
    required this.stampImageBytes,
    required this.shapeType,
    required this.progress,
  });

  final String stampImageUrl;
  final Uint8List? stampImageBytes;
  final StampShapeType shapeType;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final double p = progress.clamp(0, 1);
    final double bottomCut = _interval(p, 0.22, 0.46, Curves.easeOutCubic);
    final double rightCut = _interval(p, 0.40, 0.67, Curves.easeOutCubic);
    final double stampMove = _interval(p, 0.48, 0.90, Curves.easeInOutCubic);
    final double sourceMatte = _interval(p, 0.28, 0.52, Curves.easeOutCubic);
    final double fadeToOutput = _interval(p, 0.84, 1.0, Curves.easeOutCubic);
    final double shutterFlash = (1 - _interval(p, 0.0, 0.12, Curves.easeOut))
        .clamp(0, 1);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          final ui.Rect aperture = _resolveGuideRectInViewport(
            viewportSize: ui.Size(constraints.maxWidth, constraints.maxHeight),
            shapeType: shapeType,
          );

          final double bottomHeight = aperture.height * 0.24;
          final double bottomWidth = aperture.width * 0.92 * bottomCut;
          final double rightWidth = aperture.width * 0.34;
          final double rightHeight = aperture.height * 0.88 * rightCut;
          final bool showCutMask =
              sourceMatte > 0 || bottomWidth > 0 || rightHeight > 0;

          final double pieceWidth = aperture.width * 0.92;
          final double pieceHeight = pieceWidth / shapeType.aspectRatio;
          final double startLeft =
              aperture.left + ((aperture.width - pieceWidth) / 2);
          final double startTop =
              aperture.top + ((aperture.height - pieceHeight) / 2);
          final double endLeft = aperture.left - (pieceWidth * 0.30);
          final double endTop = aperture.top - (pieceHeight * 0.30);
          final double pieceLeft = ui.lerpDouble(
            startLeft,
            endLeft,
            stampMove,
          )!;
          final double pieceTop = ui.lerpDouble(startTop, endTop, stampMove)!;
          final double pieceScale = ui.lerpDouble(1, 1.03, stampMove)!;

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.white.withValues(
                    alpha: shutterFlash * 0.10 + fadeToOutput * 0.14,
                  ),
                ),
              ),
              if (showCutMask)
                Positioned(
                  left: aperture.left,
                  top: aperture.top,
                  width: aperture.width,
                  height: aperture.height,
                  child: ClipPath(
                    clipper: _RelativeStampPathClipper(shapeType: shapeType),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (sourceMatte > 0)
                          ColoredBox(
                            color: AppColors.black.withValues(
                              alpha: sourceMatte * 0.92,
                            ),
                          ),
                        if (bottomWidth > 0)
                          Positioned(
                            left: 0,
                            bottom: 0,
                            width: bottomWidth,
                            height: bottomHeight,
                            child: ColoredBox(
                              color: AppColors.black.withValues(alpha: 0.92),
                            ),
                          ),
                        if (rightHeight > 0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            width: rightWidth,
                            height: rightHeight,
                            child: ColoredBox(
                              color: AppColors.black.withValues(alpha: 0.92),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: pieceLeft,
                top: pieceTop,
                child: Transform.scale(
                  scale: pieceScale,
                  child: StampverseStamp(
                    imageUrl: stampImageUrl,
                    imageBytes: stampImageBytes,
                    shapeType: shapeType,
                    width: pieceWidth,
                  ),
                ),
              ),
              if (fadeToOutput > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.white.withValues(
                      alpha: fadeToOutput * 0.14,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _interval(double t, double begin, double end, Curve curve) {
    final double normalized = ((t - begin) / (end - begin)).clamp(0, 1);
    return curve.transform(normalized);
  }
}

class _RelativeStampPathClipper extends CustomClipper<Path> {
  const _RelativeStampPathClipper({required this.shapeType});

  final StampShapeType shapeType;

  @override
  Path getClip(Size size) {
    return buildStampShapePath(rect: Offset.zero & size, shapeType: shapeType);
  }

  @override
  bool shouldReclip(covariant _RelativeStampPathClipper oldClipper) {
    return oldClipper.shapeType != shapeType;
  }
}

class _StampGuideOverlay extends StatelessWidget {
  const _StampGuideOverlay({
    required this.shapeType,
    this.dimAlpha = 0.28,
    this.strokeWidth = 3.6,
  });

  final StampShapeType shapeType;
  final double dimAlpha;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StampGuidePainter(
        shapeType: shapeType,
        dimAlpha: dimAlpha,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _StampGuidePainter extends CustomPainter {
  const _StampGuidePainter({
    required this.shapeType,
    required this.dimAlpha,
    required this.strokeWidth,
  });

  final StampShapeType shapeType;
  final double dimAlpha;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Rect guideRect = _resolveGuideRectInViewport(
      viewportSize: ui.Size(size.width, size.height),
      shapeType: shapeType,
    );
    final Path stampPath = buildStampShapePath(
      rect: guideRect,
      shapeType: shapeType,
    );

    final Path fullScreenPath = Path()..addRect(Offset.zero & size);
    final Path shadedOutside = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      stampPath,
    );

    canvas.drawPath(
      shadedOutside,
      Paint()..color = AppColors.black.withValues(alpha: dimAlpha),
    );

    canvas.drawPath(
      stampPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.8
        ..color = AppColors.white.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      stampPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _StampGuidePainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.dimAlpha != dimAlpha ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _CropPreview extends StatefulWidget {
  const _CropPreview({
    super.key,
    required this.imageUrl,
    required this.shapeType,
  });

  final String imageUrl;
  final StampShapeType shapeType;

  @override
  State<_CropPreview> createState() => _CropPreviewState();
}

class _CropPreviewState extends State<_CropPreview> {
  ui.Image? _sourceImage;
  bool _isLoading = true;
  double _scale = 1;
  double _gestureStartScale = 1;
  Offset _offset = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadSourceImage();
  }

  @override
  void didUpdateWidget(covariant _CropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadSourceImage();
    }
  }

  @override
  void dispose() {
    _sourceImage?.dispose();
    super.dispose();
  }

  Future<void> _loadSourceImage() async {
    _sourceImage?.dispose();
    _sourceImage = null;
    setState(() {
      _isLoading = true;
      _scale = 1;
      _offset = Offset.zero;
    });

    try {
      final Uint8List? bytes = await _resolveImageBytes(widget.imageUrl);
      if (bytes == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      codec.dispose();

      if (!mounted) {
        frameInfo.image.dispose();
        return;
      }

      setState(() {
        _sourceImage = frameInfo.image;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _resolveImageBytes(String value) async {
    try {
      if (value.startsWith('data:image')) {
        final int comma = value.indexOf(',');
        if (comma < 0 || comma >= value.length - 1) return null;
        return base64Decode(value.substring(comma + 1));
      }
      if (value.startsWith('http://') || value.startsWith('https://')) {
        final ByteData data = await NetworkAssetBundle(
          Uri.parse(value),
        ).load(value);
        return data.buffer.asUint8List();
      }
      final ByteData data = await rootBundle.load(value);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  _ResolvedCropImageLayout _resolveLayout({
    required ui.Image image,
    required Size viewportSize,
    required ui.Rect guideRect,
    required double scale,
    required Offset offset,
  }) {
    final double imageWidth = image.width.toDouble();
    final double imageHeight = image.height.toDouble();
    final double baseScale = math.max(
      viewportSize.width / imageWidth,
      viewportSize.height / imageHeight,
    );
    final double renderedWidth = imageWidth * baseScale * scale;
    final double renderedHeight = imageHeight * baseScale * scale;
    final double centeredLeft = (viewportSize.width - renderedWidth) / 2;
    final double centeredTop = (viewportSize.height - renderedHeight) / 2;
    final double minDx = guideRect.right - (centeredLeft + renderedWidth);
    final double maxDx = guideRect.left - centeredLeft;
    final double minDy = guideRect.bottom - (centeredTop + renderedHeight);
    final double maxDy = guideRect.top - centeredTop;
    final Offset clampedOffset = Offset(
      offset.dx.clamp(minDx, maxDx),
      offset.dy.clamp(minDy, maxDy),
    );
    final double left = centeredLeft + clampedOffset.dx;
    final double top = centeredTop + clampedOffset.dy;

    return _ResolvedCropImageLayout(
      left: left,
      top: top,
      width: renderedWidth,
      height: renderedHeight,
      clampedOffset: clampedOffset,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
    _gestureStartOffset = _offset;
    _gestureStartFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final ui.Image? image = _sourceImage;
    if (image == null) return;
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) return;
    final ui.Rect guideRect = _resolveGuideRectInViewport(
      viewportSize: ui.Size(_viewportSize.width, _viewportSize.height),
      shapeType: widget.shapeType,
    );

    final double nextScale = (_gestureStartScale * details.scale).clamp(1, 4);
    final Offset delta = details.focalPoint - _gestureStartFocalPoint;
    final Offset nextOffset = _gestureStartOffset + delta;
    final _ResolvedCropImageLayout nextLayout = _resolveLayout(
      image: image,
      viewportSize: _viewportSize,
      guideRect: guideRect,
      scale: nextScale,
      offset: nextOffset,
    );

    setState(() {
      _scale = nextScale;
      _offset = nextLayout.clampedOffset;
    });
  }

  Future<String?> exportCroppedImageDataUrl() async {
    final ui.Image? image = _sourceImage;
    if (image == null) return null;
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) return null;
    final ui.Rect guideRect = _resolveGuideRectInViewport(
      viewportSize: ui.Size(_viewportSize.width, _viewportSize.height),
      shapeType: widget.shapeType,
    );

    try {
      final _ResolvedCropImageLayout layout = _resolveLayout(
        image: image,
        viewportSize: _viewportSize,
        guideRect: guideRect,
        scale: _scale,
        offset: _offset,
      );

      final double imageWidth = image.width.toDouble();
      final double imageHeight = image.height.toDouble();
      final double left =
          ((guideRect.left - layout.left) / layout.width * imageWidth).clamp(
            0,
            imageWidth,
          );
      final double top =
          ((guideRect.top - layout.top) / layout.height * imageHeight).clamp(
            0,
            imageHeight,
          );
      final double right =
          ((guideRect.right - layout.left) / layout.width * imageWidth).clamp(
            left + 1,
            imageWidth,
          );
      final double bottom =
          ((guideRect.bottom - layout.top) / layout.height * imageHeight).clamp(
            top + 1,
            imageHeight,
          );

      final ui.Rect sourceRect = ui.Rect.fromLTRB(left, top, right, bottom);
      final int targetWidth = sourceRect.width.round().clamp(1, 4096);
      final int targetHeight = sourceRect.height.round().clamp(1, 4096);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        sourceRect,
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint(),
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(
        targetWidth,
        targetHeight,
      );
      final ByteData? data = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();

      if (data == null) return null;
      final String encoded = base64Encode(data.buffer.asUint8List());
      return 'data:image/png;base64,$encoded';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.stampversePrimaryText,
        ),
      );
    }

    final ui.Image? image = _sourceImage;
    if (image == null) {
      return const Center(child: _PreviewFallback());
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 360),
        child: AspectRatio(
          aspectRatio: widget.shapeType.aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.stampversePrimaryText,
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (_, BoxConstraints constraints) {
                  _viewportSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final ui.Rect guideRect = _resolveGuideRectInViewport(
                    viewportSize: ui.Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                    shapeType: widget.shapeType,
                  );
                  final _ResolvedCropImageLayout layout = _resolveLayout(
                    image: image,
                    viewportSize: _viewportSize,
                    guideRect: guideRect,
                    scale: _scale,
                    offset: _offset,
                  );

                  return GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Positioned(
                          left: layout.left,
                          top: layout.top,
                          width: layout.width,
                          height: layout.height,
                          child: RawImage(image: image, fit: BoxFit.fill),
                        ),
                        IgnorePointer(
                          child: _StampGuideOverlay(
                            shapeType: widget.shapeType,
                            dimAlpha: 0.14,
                            strokeWidth: 3.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedCropImageLayout {
  const _ResolvedCropImageLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.clampedOffset,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Offset clampedOffset;
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.stampverseSurface,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.stampverseMutedText,
        ),
      ),
    );
  }
}
