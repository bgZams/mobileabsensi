import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sp_util/sp_util.dart';

Future<void> initializeDeviceInfo() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      String deviceId = androidInfo.id;
      String systemVersion = androidInfo.version.release ?? 'Unknown';
      
      await SpUtil.putString('device_id', deviceId);
      await SpUtil.putString('system_version', systemVersion);
    } else {
      // Fallback for other platforms
      await SpUtil.putString('device_id', 'fallback_${DateTime.now().millisecondsSinceEpoch}');
      await SpUtil.putString('system_version', 'Unknown');
    }
  } catch (e) {
    // Fallback if error occurs
    debugPrint("Error getting device info: $e");
    await SpUtil.putString('device_id', 'fallback_${DateTime.now().millisecondsSinceEpoch}');
    await SpUtil.putString('system_version', 'Unknown');
  }
}