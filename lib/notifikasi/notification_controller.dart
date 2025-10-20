import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart'; // Import ini untuk GlobalKey<NavigatorState>
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// GlobalKey untuk navigasi dari mana saja (terutama dari background)
// Pastikan ini adalah navigatorKey yang sama yang digunakan di MaterialApp Anda.
GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

// Stream untuk menangani payload notifikasi saat aplikasi dibuka dari notifikasi
final BehaviorSubject<String?> selectNotificationStream =
    BehaviorSubject<String?>();

class NotificationController {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    // Inisialisasi pengaturan untuk Android dan iOS
    // Ganti 'app_icon' dengan nama file ikon notifikasi Anda
    // Letakkan file ini di android/app/src/main/res/drawable/
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );

    // Meminta izin notifikasi (penting untuk Android 13+ dan iOS)
    _requestPermissions();
  }

  static void _requestPermissions() {
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); // Untuk Android 13+

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Dipanggil saat notifikasi diterima saat aplikasi berjalan di foreground (hanya iOS < 10)
  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    debugPrint('Notifikasi diterima di foreground (iOS < 10): $payload');
    if (payload != null) {
      selectNotificationStream.add(payload);
    }
  }

  // Dipanggil saat pengguna mengetuk notifikasi (aplikasi foreground atau background)
  static void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    debugPrint('Notifikasi diketuk: ${notificationResponse.payload}');
    switch (notificationResponse.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        selectNotificationStream.add(notificationResponse.payload);
        break;
      case NotificationResponseType.selectedNotificationAction:
        // Handle aksi notifikasi (jika ada)
        // if (notificationResponse.actionId == 'some_action_id') {
        //   // Lakukan sesuatu
        // }
        break;
    }
  }

  // Fungsi callback untuk notifikasi yang diketuk saat aplikasi dihentikan (terminated)
  // Penting: Harus berupa top-level function atau static method dengan @pragma('vm:entry-point')
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    debugPrint('Notifikasi diketuk (background/terminated): ${notificationResponse.payload}');
    // Menggunakan sendPort untuk mengirim payload ke isolate utama
    final SendPort? send = IsolateNameServer.lookupPortByName('notification_send_port');
    if (send != null) {
      send.send(notificationResponse.payload);
    }
  }

  // --- Fungsi untuk inisialisasi Isolate Receive Port (untuk background execution) ---
  static ReceivePort? _receivePort;

  static Future<void> initializeIsolateReceivePort() async {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'notification_send_port',
    );
    _receivePort!.listen((dynamic data) {
      debugPrint('Data dari isolate (ReceivePort): $data');
      if (data is String) {
        // Navigasi ke halaman yang sesuai berdasarkan payload
        _handleNotificationPayload(data);
      }
    });
  }

  // Fungsi untuk menangani payload notifikasi dan navigasi
  static void _handleNotificationPayload(String? payload) {
    if (payload == null) return;

    if (globalNavigatorKey.currentState == null) {
      debugPrint('Navigator state is null in _handleNotificationPayload. Cannot navigate.');
      return;
    }

    if (payload.startsWith('izin_')) {
      final izinId = payload.substring(5);
      if (izinId.isNotEmpty) {
        globalNavigatorKey.currentState!.pushNamed(
          '/detail-konfirmasi-izin',
          arguments: {'id_izin': izinId},
        );
      }
    } else if (payload.startsWith('laporan_')) {
      final laporanId = payload.substring(8);
      if (laporanId.isNotEmpty) {
        globalNavigatorKey.currentState!.pushNamed(
          '/status-laporan',
          arguments: {'id_laporan': laporanId},
        );
      }
    }
  }

  // --- Fungsi untuk membuat notifikasi baru ---
  static Future<void> createNewNotificationIzin(
    int id,
    String idAtasan,
    String? jenisIzin,
    int? idStatus,
    String keyNotif, {
    required String payloadId, // Payload ini WAJIB ada
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'izin_channel_id', // ID Channel unik
      'Notifikasi Izin', // Nama Channel yang akan terlihat di pengaturan Android
      channelDescription: 'Notifikasi untuk pengajuan izin baru',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker', // Teks yang muncul di status bar sebentar
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    String title = "Pengajuan Izin Baru";
    String body = "Ada pengajuan $jenisIzin baru yang menunggu konfirmasi Anda.";

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'izin_$payloadId', // Format payload untuk navigasi
    );
  }

  static Future<void> createNewNotificationLaporan(
    int id,
    String idAtasan,
    String? jenisLaporan, // Tidak digunakan untuk laporan, bisa diatur null
    int? idStatus,
    String keyNotif, {
    required String payloadId, // Payload ini WAJIB ada
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'laporan_channel_id', // ID Channel unik
      'Notifikasi Laporan Harian', // Nama Channel yang akan terlihat di pengaturan Android
      channelDescription: 'Notifikasi untuk laporan harian baru',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    String title = "Laporan Harian Baru";
    String body = "Ada laporan harian baru yang menunggu konfirmasi Anda.";

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'laporan_$payloadId', // Format payload untuk navigasi
    );
  }
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Pastikan timezone sudah diinisialisasi sebelum memanggil zonedSchedule
    tz.initializeTimeZones();
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel_id',
          'Scheduled Notifications',
          channelDescription: 'Notifikasi terjadwal',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  } 
  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();
  // Membatalkan notifikasi berdasarkan ID
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Membatalkan semua notifikasi
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}