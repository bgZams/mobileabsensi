import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/auth/login_first.dart';
import 'package:mobileabsensi/firebase_options.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/admin/absen.dart';
import 'package:mobileabsensi/frontend/admin/detail_pegawai.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';
import 'package:mobileabsensi/frontend/admin/lhk.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/frontend/izin/detail_konfirmasi_atasan.dart';
import 'package:mobileabsensi/frontend/izin/izin.dart';
import 'package:mobileabsensi/frontend/absen/laporan_harian.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/frontend/izin/buat.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/laporan_harian/buat.dart';
import 'package:mobileabsensi/frontend/laporan_harian/laporan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/riwayat_pengajuan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/status.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:mobileabsensi/frontend/profile.dart';
import 'package:mobileabsensi/frontend/senam.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobileabsensi/frontend/teknis/pending_wifi.dart';
import 'package:mobileabsensi/singgah.dart';
import 'package:sp_util/sp_util.dart';
import 'package:flutter/services.dart';

// Global Declarations
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

String? globalIdAtasan;
Map<String, dynamic> globalUpdateData = {};
String? idUser;

// Screen Recording Control
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

// HTTP Overrides for Android API 23-28
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  await SpUtil.getInstance();
  idUser = SpUtil.getString('id_user');
  _checkAndUpdatePreferences();
  await enableSecureScreen();

  NotificationController.selectNotificationStream.stream.listen((String? payload) {
    if (payload != null) {
      debugPrint('Payload diterima di main (selectNotificationStream): $payload');
      _handleNotificationPayloadInMain(payload);
    }
  });

  if (Platform.isAndroid) {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 23 && androidInfo.version.sdkInt <= 28) {
        HttpOverrides.global = MyHttpOverrides();
        if (kDebugMode) print("HttpOverrides applied for Android API 23.");
      }
    } catch (e) {
      if (kDebugMode) print("Error getting device info: $e");
    }
  }

  runApp(const MyApp());
}

// Notification Payload Handler
void _handleNotificationPayloadInMain(String payload) {
  final navState = navigatorKey.currentState;
  if (navState == null) {
    debugPrint('Navigator state is null, cannot navigate from notification payload: $payload');
    return;
  }

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

// Daily Preferences Reset
void _checkAndUpdatePreferences() {
  final now = DateTime.now();
  final todayString = DateFormat('yyyy-MM-dd').format(now);
  final savedDate = SpUtil.getString('saved_date');

  if (savedDate != todayString) {
    for (final key in [
      'masuk',
      'is_codeMasuk',
      'pulang',
      'is_codePulang',
      'saved_date'
    ]) {
      SpUtil.remove(key);
    }
    SpUtil.putBool('is_codeMasuk', false);
    SpUtil.putBool('is_codePulang', false);
    SpUtil.putBool('is_PulangCepat', false);
    SpUtil.putBool('_isMasuk', false);
    SpUtil.putBool('_isPulang', false);
    SpUtil.putString('saved_date', todayString);
  }
}

// Firebase Data Listener
Future<void> readData() async {
  final databaseReference = FirebaseDatabase.instance.ref();
  databaseReference.child('izin').onValue.listen(
    (event) => processSnapshot(event.snapshot, 'izin'),
    onError: (error) => debugPrint('Terjadi kesalahan pada child izin: $error'),
  );
  databaseReference.child('laporan').onValue.listen(
    (event) => processSnapshot(event.snapshot, 'laporan'),
    onError: (error) => debugPrint('Terjadi kesalahan pada child laporan: $error'),
  );
}

// Firebase Snapshot Processor
void processSnapshot(DataSnapshot? snapshot, String notificationType) async {
  if (snapshot == null || snapshot.value == null) return;
  final data = snapshot.value as Map<dynamic, dynamic>?;
  if (data == null || data.isEmpty) {
    debugPrint('Data $notificationType tidak ditemukan');
    return;
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final processedKey = 'processed_${notificationType}_ids';
  final processedIds = Set<String>.from(SpUtil.getStringList(processedKey) ?? []);

  final validEntries = data.entries.where((entry) {
    if (processedIds.contains(entry.key)) return false;
    final doc = entry.value as Map<dynamic, dynamic>?;
    final timestamp = doc?['timestamp'] as int?;
    final idStatus = doc?['id_status'];
    return timestamp != null &&
        timestamp > (now - 300000) &&
        timestamp <= now &&
        idStatus == 0;
  }).toList();

  if (validEntries.isEmpty) {
    debugPrint('Tidak ada data $notificationType baru yang perlu diproses');
    return;
  }

  validEntries.sort((a, b) {
    final aTimestamp = (a.value as Map<dynamic, dynamic>)['timestamp'] as int;
    final bTimestamp = (b.value as Map<dynamic, dynamic>)['timestamp'] as int;
    return bTimestamp.compareTo(aTimestamp);
  });

  final latestEntry = validEntries.first;
  final documentData = latestEntry.value as Map<dynamic, dynamic>;
  final entryKey = latestEntry.key.toString();
  final idAtasan = documentData['id_atasan'];
  final idStatus = documentData['id_status'];
  final jenisIzin = documentData['jenis_izin'];
  final user = SpUtil.getString('id_user');
  final userId = int.tryParse(user ?? '');
  final parsedIdAtasan = int.tryParse(idAtasan.toString());

  if (userId == parsedIdAtasan) {
    try {
      final databaseReference = FirebaseDatabase.instance.ref();
      switch (notificationType) {
        case 'izin':
          await NotificationController.createNewNotificationIzin(
            1,
            idAtasan.toString(),
            jenisIzin,
            idStatus,
            notificationType,
            payloadId: entryKey,
          );
          await databaseReference.child('izin').child(entryKey).update({'id_status': 2});
          break;
        case 'laporan':
          await NotificationController.createNewNotificationLaporan(
            2,
            idAtasan.toString(),
            null,
            idStatus,
            notificationType,
            payloadId: entryKey,
          );
          await databaseReference.child('laporan').child(entryKey).update({'id_status': 2});
          break;
      }
      processedIds.add(entryKey);
      await SpUtil.putStringList(processedKey, processedIds.toList());
      debugPrint('Berhasil memproses notifikasi $notificationType dengan ID: $entryKey');
    } catch (e) {
      if (kDebugMode) print('Error sending $notificationType notification: $e');
    }
  } else {
    debugPrint('ID atasan tidak cocok dengan user saat ini untuk $notificationType: $entryKey');
  }
}

// Main App Widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    globalNavigatorKey = navigatorKey;
    NotificationController.selectNotificationStream.stream.listen((String? payload) {
      if (payload != null && navigatorKey.currentState != null) {
        _handleNotificationPayloadInMain(payload);
      }
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) => enableSecureScreen());
  }

  @override
  Widget build(BuildContext context) {
    final idGroups = SpUtil.getString('id_groups');
    Widget homeWidget;
    if (idGroups == "3" || idGroups == "5") {
      homeWidget = const Singgah();
    } else if (idGroups == "2") {
      homeWidget = const Admin();
    } else {
      SpUtil.clear();
      homeWidget = const Login();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Absensi',
      navigatorKey: navigatorKey,
      home: homeWidget,
      routes: {
        '/login-first': (context) => const LoginFirst(),
        '/login': (context) => const Login(),
        '/absen': (context) => const Absen(),
        '/dashboard': (context) => const Dashboard(initialIndex: 0),
        '/absen-masuk': (context) => const Absen(),
        '/profil': (context) => const Profile(),
        '/riwayat': (context) => const RiwayatAbsen(),
        '/laporan': (context) => const Laporan(),
        '/create-laporan': (context) => const BuatLaporan(),
        '/riwayat-laporan': (context) => const LaporanHarian(),
        '/riwayat-laporan/pengajuan': (context) => const RiwayatPengajuanLhk(),
        '/status-laporan': (context) => const StatusLaporan(),
        '/izin': (context) => const Izin(),
        '/buat_izin': (context) => const BuatIzin(),
        '/konfirmasi-izin': (context) => const KonfirmasiIzin(),
        '/detail-konfirmasi-izin': (context) => const DetailKonfirmasiIzinAtasan(),
        '/apel': (context) => const Apel(),
        '/senam': (context) => const Senam(),
        '/pengumuman': (context) => const Pengumuman(),
        '/wifi/pending': (context) => const WifiPendding(),
        '/admin': (context) => const Admin(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name!);
        if (uri.pathSegments.length == 3 && uri.pathSegments[0] == 'admin') {
          final idPegawai = uri.pathSegments[2];
          final route = uri.pathSegments[1];
          Widget? page; 
          switch (route) {
            case 'detail':
              page = DetailPage(idPegawai: idPegawai);
              break;
            case 'lhk':
              page = LhkPage(idPegawai: idPegawai);
              break;
            case 'absen':
              page = AbsenPage(idPegawai: idPegawai);
              break;
            default:
              return null;
          }
          return MaterialPageRoute(builder: (context) => page!);
        }
        return null;
      },
    );
  }
}
