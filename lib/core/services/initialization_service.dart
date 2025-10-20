import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobileabsensi/core/services/attendance_manager.dart';
import 'package:mobileabsensi/core/services/device_info_service.dart';
import 'package:mobileabsensi/core/services/firebase_service.dart';
import 'package:mobileabsensi/core/services/notification_service.dart';
import 'package:mobileabsensi/core/utils/http_overrides.dart';
import 'package:mobileabsensi/firebase_options.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:mobileabsensi/core/constants/app_constants.dart';
import 'package:sp_util/sp_util.dart';
import 'dart:io';

/// Fungsi utama untuk menginisialisasi semua layanan dan konfigurasi aplikasi
Future<void> initializeApp() async {
  debugPrint("Initializing App...");
  
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi paket-paket penting
  await SpUtil.getInstance();
  await initializeDateFormatting('id_ID', null);
  
  // Inisialisasi notifikasi
  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();
  
  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Firebase Initialized.");
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  // Inisialisasi listener notifikasi dan Firebase
  initializeNotificationListener();
  readData();
  
  // Simpan ID user dari SPUtil ke variabel global
  idUser = SpUtil.getString('id_user');
  
  // Cek dan perbarui preferensi absen
  checkAndUpdatePreferences();
  
  // Konfigurasi HTTP untuk Android API lama
  if (Platform.isAndroid) {
    HttpOverrides.global = MyHttpOverrides();
    if (kDebugMode) print("HttpOverrides applied for Android API 23.");
  }
  
  // Inisialisasi info perangkat jika belum ada
  String? deviceId = SpUtil.getString('device_id');
  if (deviceId == null || deviceId.isEmpty) {
    await initializeDeviceInfo();
  }
  
  // Aktifkan secure screen (jika diperlukan)
  // await enableSecureScreen();

  debugPrint("App Initialization Complete.");
}