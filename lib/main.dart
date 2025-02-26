import 'dart:io';
import 'dart:async';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/firebase_options.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/admin/absen.dart';
import 'package:mobileabsensi/frontend/admin/detail_pegawai.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';
import 'package:mobileabsensi/frontend/admin/lhk.dart';
import 'package:mobileabsensi/frontend/izin/detail_konfirmasi_atasan.dart';
import 'package:mobileabsensi/frontend/izin/izin.dart';
import 'package:mobileabsensi/frontend/absen/laporan_harian.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/frontend/izin/buat.dart';
import 'package:mobileabsensi/frontend/izin/edit.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/izin/riwayat.dart';
import 'package:mobileabsensi/frontend/izin/status.dart';
import 'package:mobileabsensi/frontend/laporan_harian/buat.dart';
import 'package:mobileabsensi/frontend/laporan_harian/konfirmasi_laporan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/laporan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/riwayat_pengajuan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/status.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:mobileabsensi/frontend/profile.dart';
import 'package:mobileabsensi/frontend/senam.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobileabsensi/frontend/teknis/pending_wifi.dart';
import 'package:sp_util/sp_util.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? globalIdAtasan;
Map<String, dynamic> globalUpdateData = {};
String? idUser;
String? keyNotif;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  await SpUtil.getInstance();
  idUser = SpUtil.getString('id_user');
  await readData();
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

Future<void> readData() async {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  databaseReference.child('izin').onValue.listen((event) {
    processSnapshot(event.snapshot, 'izin');
  }, onError: (error) {
    debugPrint('Terjadi kesalahan pada child izin: $error');
  });

  databaseReference.child('laporan').onValue.listen((event) {
    processSnapshot(event.snapshot, 'laporan');
  }, onError: (error) {
    debugPrint('Terjadi kesalahan pada child laporan: $error');
  });
}

void processSnapshot(DataSnapshot? snapshot, String keyNotif) async {
  if (snapshot != null && snapshot.value != null) {
    final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
    if (data != null && data.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Simpan ID yang sudah diproses
      final String processedKey = 'processed_${keyNotif}_ids';
      final Set<String> processedIds = Set<String>.from(
        SpUtil.getStringList(processedKey) ?? []
      );
      
      // Filter entri yang belum diproses dan timestamp-nya valid
      final validEntries = data.entries.where((entry) {
        // Periksa apakah entri sudah diproses sebelumnya
        if (processedIds.contains(entry.key)) {
          return false;
        }
        
        final documentData = entry.value as Map<dynamic, dynamic>?;
        final timestamp = documentData?['timestamp'] as int?;
        final idStatus = documentData?['id_status'];
        
        // Hanya ambil entri dengan status 0 dan timestamp yang valid
        // Gunakan "now - 300000" (5 menit yang lalu) untuk menghindari entri lama
        return timestamp != null && 
               timestamp > (now - 300000) && 
               timestamp <= now && 
               idStatus == 0;
      }).toList();
      
      if (validEntries.isEmpty) {
        debugPrint('Tidak ada data $keyNotif baru yang perlu diproses');
        return;
      }
      
      // Urutkan berdasarkan timestamp terbaru
      validEntries.sort((a, b) {
        final aTimestamp = (a.value as Map<dynamic, dynamic>)['timestamp'] as int;
        final bTimestamp = (b.value as Map<dynamic, dynamic>)['timestamp'] as int;
        return bTimestamp.compareTo(aTimestamp); // Urutkan dari terbaru
      });
      
      // Ambil entri terbaru
      final latestEntry = validEntries.first;
      final documentData = latestEntry.value as Map<dynamic, dynamic>;
      
      final idAtasan = documentData['id_atasan'];
      final idStatus = documentData['id_status'];
      final jenisIzin = documentData['jenis_izin'];
      final parsedIdAtasan = int.tryParse(idAtasan.toString());
      final user = SpUtil.getString('id_user');
      final userId = int.tryParse(user ?? '');
      
      if (userId == parsedIdAtasan) {
        try {
          final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
          switch (keyNotif) {
            case 'izin':
              NotificationController.createNewNotificationIzin(1, idAtasan, jenisIzin, idStatus, keyNotif);
              databaseReference.child('izin').child(latestEntry.key).update({'id_status': 2});
              break;
            case 'laporan':
              NotificationController.createNewNotificationLaporan(1, idAtasan, jenisIzin, idStatus, keyNotif);
              databaseReference.child('laporan').child(latestEntry.key).update({'id_status': 2});
              break;
          }
          
          // Simpan ID yang sudah diproses
          processedIds.add(latestEntry.key);
          SpUtil.putStringList(processedKey, processedIds.toList());
          
          debugPrint('Berhasil memproses notifikasi $keyNotif dengan ID: ${latestEntry.key}');
        } catch (e) {
          if (kDebugMode) {
            print('Error sending $keyNotif notification: $e');
          }
        }
      } else {
        debugPrint('ID atasan tidak cocok dengan user saat ini');
      }
    } else {
      debugPrint('Data $keyNotif tidak ditemukan');
    }
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final int _currentIndex = 0;
  final _pageController = PageController();
  void initState() {
    _checkAndUpdatePreferences();
  }

  void _checkAndUpdatePreferences() {
    DateTime now = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(now);
    String? savedDate = SpUtil.getString('saved_date');
    if (savedDate != todayString) {
      SpUtil.remove('masuk');
      SpUtil.remove('is_codeMasuk');
      SpUtil.remove('pulang');
      SpUtil.remove('is_codePulang');
      SpUtil.remove('saved_date');
      SpUtil.putBool('is_codeMasuk', false);
      SpUtil.putBool('is_codePulang', false);
      SpUtil.putBool('is_PulangCepat', false);
      SpUtil.putBool('_isMasuk', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Absensi',
      navigatorKey: navigatorKey,
      routes: {
        '/login': (context) => const Login(),
        '/home-page': (context) => const Home(title: 'Mobile Absensi'),
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
        '/update-izin': (context) => const EditIzin(),
        '/riwayat-izin': (context) => const RiwayatIzin(),
        '/status-izin': (context) => const StatusIzin(),
        '/konfirmasi-izin': (context) => const KonfirmasiIzin(),
        '/detail-konfirmasi-izin': (context) => const DetailKonfirmasiIzinAtasan(),
        '/konfirmasi-laporan': (context) => const KonfirmasiLaporanHarian(),
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
          Widget page;
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
          return MaterialPageRoute(builder: (context) => page);
        }
        return null;
      },
      initialRoute: (SpUtil.getString('id_groups').toString() == "3" || SpUtil.getString('id_groups').toString() == "5" ? '/home-page' : (SpUtil.getString('id_groups').toString() == "2" ? '/admin' : '/login')),
      home: Scaffold(
        body: PageView(
          controller: _pageController,
          children: const <Widget>[
            Absen(),
            RiwayatAbsen(),
            Izin(),
            LaporanHarian(),
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          color: const Color.fromARGB(255, 14, 60, 129),
          height: 65,
          index: _currentIndex,
          items: <Widget>[
            _buildIcon(Icons.home, 0),
            _buildIcon(Icons.timer, 1),
            _buildIcon(Icons.mail, 2),
            _buildIcon(Icons.assignment, 3),
          ],
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: _currentIndex == index
              ? [const Color.fromARGB(255, 235, 120, 255), const Color.fromARGB(255, 159, 124, 255)]
              : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Icon(
        icon,
        size: 35,
        color: Colors.white,
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Implement proper certificate validation here.
        return false;
      };
  }
}