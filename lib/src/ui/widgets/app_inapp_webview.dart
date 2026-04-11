import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stamp_camera/src/ui/widgets/custom_circular_progress.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class AppInAppWebView extends StatefulWidget {
  final String? url;
  final String? assetFilePath;
  final Function(List<dynamic>)? callback;

  const AppInAppWebView({
    super.key,
    this.url,
    this.assetFilePath,
    this.callback,
  }) : assert(
         (url != null && assetFilePath == null) ||
             (url == null && assetFilePath != null),
         'Provide either url or assetFilePath.',
       );

  @override
  State<AppInAppWebView> createState() => _AppInAppWebViewState();
}

class _AppInAppWebViewState extends State<AppInAppWebView> {
  bool _isLoading = true;

  void _setLoading(bool value) {
    if (!mounted || _isLoading == value) return;
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        InAppWebView(
          gestureRecognizers: {Factory(() => EagerGestureRecognizer())},
          initialUrlRequest: widget.url == null
              ? null
              : URLRequest(url: WebUri(widget.url!)),
          initialFile: widget.assetFilePath,
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: false,
            transparentBackground: true,
            javaScriptEnabled: true,
          ),
          onLoadStart: (_, _) => _setLoading(true),
          onProgressChanged: (_, progress) => _setLoading(progress < 100),
          onLoadStop: (_, _) => _setLoading(false),
          onReceivedError: (_, _, _) {
            _setLoading(false);
            // TODO: Show error alert message (Error in receive data from server)
          },
          onReceivedHttpError: (_, _, _) {
            _setLoading(false);
            // TODO: Show error alert message (Error in receive data from server)
          },
          onConsoleMessage: (_, _) {},
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: AppColors.surfacePage,
              child: CustomCircularProgress(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
