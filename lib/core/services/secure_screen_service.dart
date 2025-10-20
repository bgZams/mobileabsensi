import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

const MethodChannel _screenRecordingChannel = MethodChannel('com.mobileabsensi/secure_screen');

Future<void> enableSecureScreen() async {
  if (!Platform.isAndroid) return;
  try {
    await _screenRecordingChannel.invokeMethod('setSecureScreen', {'enable': true});
    debugPrint('Screen recording prevention ENABLED.');
  } on PlatformException catch (e) {
    debugPrint("Failed to enable secure screen: '${e.message}'.");
  }
}

Future<void> disableSecureScreen() async {
  if (!Platform.isAndroid) return;
  try {
    await _screenRecordingChannel.invokeMethod('setSecureScreen', {'enable': false});
    debugPrint('Screen recording prevention DISABLED.');
  } on PlatformException catch (e) {
    debugPrint("Failed to disable secure screen: '${e.message}'.");
  }
}