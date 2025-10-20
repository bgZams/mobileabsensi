import 'package:flutter/foundation.dart';
import 'package:mobileabsensi/core/constants/app_constants.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';

/// Menangani payload (data) dari notifikasi yang diklik pengguna
void handleNotificationPayload(String payload) {
  final navState = navigatorKey.currentState;
  if (navState == null) {
    debugPrint('Navigator state is null, cannot navigate from notification payload: $payload');
    return;
  }

  // Navigasi berdasarkan jenis payload
  if (payload.startsWith('izin_')) {
    final izinId = payload.substring(5);
    if (izinId.isNotEmpty) {
      navState.pushNamed('/detail-konfirmasi-izin', arguments: {'id_izin': izinId});
    }
  } else if (payload.startsWith('laporan_')) {
    final laporanId = payload.substring(8);
    if (laporanId.isNotEmpty) {
      navState.pushNamed('/status-laporan', arguments: {'id_laporan': laporanId});
    }
  }
}

/// Menginisialisasi listener untuk notifikasi yang diklik
void initializeNotificationListener() {
  NotificationController.selectNotificationStream.stream.listen((String? payload) {
    if (payload != null) {
      debugPrint('Payload diterima: $payload');
      handleNotificationPayload(payload);
    }
  });
}