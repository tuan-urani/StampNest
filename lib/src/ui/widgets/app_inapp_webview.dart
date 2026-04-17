import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stamp_camera/src/ui/widgets/custom_circular_progress.dart';
import 'package:stamp_camera/src/utils/app_colors.dart';

class AppInAppWebView extends StatefulWidget {
  final String? url;
  final String? assetFilePath;
  final String? preferredLanguageCode;
  final Function(List<dynamic>)? callback;

  const AppInAppWebView({
    super.key,
    this.url,
    this.assetFilePath,
    this.preferredLanguageCode,
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

  String? get _legalLanguageCode {
    final String? preferredLanguageCode = widget.preferredLanguageCode;
    if (preferredLanguageCode == null || preferredLanguageCode.isEmpty) {
      return null;
    }
    final String normalizedLanguageCode = preferredLanguageCode.toLowerCase();
    if (normalizedLanguageCode == 'vi') return 'vi';
    if (normalizedLanguageCode == 'ja') return 'ja';
    return 'en';
  }

  void _setLoading(bool value) {
    if (!mounted || _isLoading == value) return;
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _applyPreferredLanguage(
    InAppWebViewController controller,
  ) async {
    final String? legalLanguageCode = _legalLanguageCode;
    if (legalLanguageCode == null) return;

    final String script =
        '''
(() => {
  const targetLang = '$legalLanguageCode';
  const buttons = Array.from(document.querySelectorAll('[data-lang]'));
  const blocks = Array.from(document.querySelectorAll('[data-content]'));
  if (buttons.length === 0 || blocks.length === 0) return;
  const availableLanguages = buttons
    .map((button) => button.getAttribute('data-lang'))
    .filter((value) => Boolean(value));
  const resolvedLang = availableLanguages.includes(targetLang)
    ? targetLang
    : (availableLanguages.includes('en') ? 'en' : availableLanguages[0]);

  buttons.forEach((button) => {
    const isActive = button.getAttribute('data-lang') === resolvedLang;
    button.classList.toggle('active', isActive);
  });

  blocks.forEach((block) => {
    const isActive = block.getAttribute('data-content') === resolvedLang;
    block.classList.toggle('active', isActive);
  });

  document.documentElement.lang = resolvedLang;
})();
''';

    try {
      await controller.evaluateJavascript(source: script);
    } catch (_) {
      // Ignore if the loaded page does not support language switching.
    }
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
          onLoadStop: (InAppWebViewController controller, _) async {
            await _applyPreferredLanguage(controller);
            _setLoading(false);
          },
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
