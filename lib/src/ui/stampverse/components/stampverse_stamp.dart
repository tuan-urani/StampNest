import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/ui/stampverse/components/stampverse_stamp_shape.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class StampverseStamp extends StatelessWidget {
  const StampverseStamp({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.shapeType = StampShapeType.scallop,
    this.width,
    this.rotationDegrees = 0,
    this.showShadow = true,
    this.onTap,
  });

  final String imageUrl;
  final Uint8List? imageBytes;
  final StampShapeType shapeType;
  final double? width;
  final double rotationDegrees;
  final bool showShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: shapeType.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: showShadow
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.stampverseShadowStamp,
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: ClipPath(
            clipper: _StampClipper(shapeType: shapeType),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: AppColors.white),
                _StampImage(imageUrl: imageUrl, imageBytes: imageBytes),
              ],
            ),
          ),
        ),
      ),
    );

    if (rotationDegrees != 0) {
      content = Transform.rotate(
        angle: rotationDegrees * math.pi / 180,
        child: content,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}

class _StampImage extends StatelessWidget {
  const _StampImage({required this.imageUrl, this.imageBytes});

  static final Map<String, Uint8List> _dataUrlCache = <String, Uint8List>{};

  final String imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final Uint8List? rawBytes = imageBytes;
    if (rawBytes != null && rawBytes.isNotEmpty) {
      return Image.memory(
        rawBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _StampFallback(),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      final Uint8List? bytes = _decodeDataUrl(imageUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _StampFallback(),
        );
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _StampFallback(),
      );
    }

    if (_isLikelyLocalPath(imageUrl)) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _StampFallback(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const _StampFallback(),
    );
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    final Uint8List? cached = _dataUrlCache[dataUrl];
    if (cached != null) {
      return cached;
    }

    final List<String> parts = dataUrl.split(',');
    if (parts.length < 2) return null;

    try {
      final Uint8List decoded = base64Decode(parts.last);
      _cacheDecodedDataUrl(dataUrl, decoded);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  bool _isLikelyLocalPath(String value) {
    return value.startsWith('/') || value.startsWith('file://');
  }

  void _cacheDecodedDataUrl(String key, Uint8List bytes) {
    const int maxEntries = 80;
    if (_dataUrlCache.length >= maxEntries) {
      _dataUrlCache.remove(_dataUrlCache.keys.first);
    }
    _dataUrlCache[key] = bytes;
  }
}

class _StampFallback extends StatelessWidget {
  const _StampFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.stampverseBackground,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.stampverseMutedText,
        ),
      ),
    );
  }
}

class _StampClipper extends CustomClipper<Path> {
  const _StampClipper({required this.shapeType});

  final StampShapeType shapeType;

  @override
  Path getClip(Size size) {
    return buildStampShapePath(rect: Offset.zero & size, shapeType: shapeType);
  }

  @override
  bool shouldReclip(covariant _StampClipper oldClipper) {
    return oldClipper.shapeType != shapeType;
  }
}
