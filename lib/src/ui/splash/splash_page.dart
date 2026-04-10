import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stamp_camera/src/ui/widgets/app_splash_state.dart';
import 'package:stamp_camera/src/utils/app_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        Get.offNamed(AppPages.main);
      });
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppSplashState());
  }
}
