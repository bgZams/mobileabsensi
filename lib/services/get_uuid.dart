import 'package:flutter/services.dart';

class DeviceUtil {
  static const platform = MethodChannel('com.example.app/device_id');

  static Future<String?> getAndroidId() async {
    try {
      final String result = await platform.invokeMethod('getAndroidID');
      return result;
    } on PlatformException catch (e) {
      print("Gagal mengambil ID: '${e.message}'.");
      return null;
    }
  }
}