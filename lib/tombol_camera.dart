import 'package:flutter/services.dart';

class FloatingCameraService {
  static const _channel = MethodChannel('com.mobileabsensi/secure_screen');

  static Future<void> showFloatingButton() async {
    await _channel.invokeMethod('showFloatingCameraButton');
  }

  static Future<void> hideFloatingButton() async {
    await _channel.invokeMethod('hideFloatingCameraButton');
  }

  static Future<void> setSecureScreen(bool enabled) async {
    await _channel.invokeMethod('setSecureScreen', {'enable': enabled});
  }
}