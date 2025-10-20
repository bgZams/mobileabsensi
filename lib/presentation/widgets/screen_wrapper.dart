import 'package:flutter/material.dart';
import 'package:mobileabsensi/services/global_screenshot_button.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  const ScreenWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlobalScreenshot(
      key: key,
      child: child,
    );
  }
}