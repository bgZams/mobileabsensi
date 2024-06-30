import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/izin/detail_konfirmasi_atasan.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/laporan_harian/riwayat_pengajuan.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);
  final String title;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
 
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.reference();
      bool _showBottomNavBar = true;
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    NotificationController.startListeningNotificationEvents();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Memeriksa dan meminta izin
  Future<void> _requestPermissions() async {
  final locationStatus = await Permission.location.request();
  final wifiStatus = await Permission.locationWhenInUse.request();
  final camera = await Permission.camera.request();
  final galleryStatus = await Permission.photos.request();
  var notificationStatus = await Permission.notification.status;

  if (notificationStatus.isDenied) {
    notificationStatus = await Permission.notification.request();
  }

  if (locationStatus.isGranted &&
      wifiStatus.isGranted &&
      camera.isGranted &&
      galleryStatus.isGranted &&
      notificationStatus.isGranted) {
    // All permissions granted, you can access location, Wi-Fi, camera, photos, and notifications.
  } else {
    // One or more permissions denied, notify the user or handle accordingly.
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        '/detail-konfirmasi-izin': (context) =>
            const DetailKonfirmasiIzinAtasan(),
        '/konfirmasi-laporan': (context) => const KonfirmasiLaporanHarian(),
        '/apel': (context) => const Apel(),
        '/senam': (context) => const Senam(),
        '/pengumuman': (context) => const Pengumuman(),
      },
      home: Scaffold(
        body: Container(
          color: const Color.fromARGB(255, 238, 238, 238),
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const <Widget>[
              Absen(),
              RiwayatAbsen(),
              Izin(),
              LaporanHarian(),
            ],
          ),
        ),
        bottomNavigationBar: _showBottomNavBar ? CurvedNavigationBar(
          backgroundColor:  const Color.fromARGB(255, 238, 238, 238),
          // buttonBackgroundColor: Colors.white,
          color: const Color.fromARGB(255, 14, 60, 129),
          height: 65,
          index: _currentIndex, // Tentukan indeks aktif
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
            setState(() {
            _currentIndex = index;
            _showBottomNavBar = true;
          });
          },
        ) : null,
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: _currentIndex == index
              ? [
                  const Color.fromARGB(255, 235, 120, 255),
                  const Color.fromARGB(255, 159, 124, 255)
                ] // Warna ungu gradian untuk ikon aktif
              : [
                  Colors.white,
             Colors.white,
                ], // Warna abu-abu untuk ikon non-aktif
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Icon(
        icon,
        size: 35,
        color: Colors.white, // Warna ikon putih, akan di-mask dengan gradian
      ),
    );
  }
}
