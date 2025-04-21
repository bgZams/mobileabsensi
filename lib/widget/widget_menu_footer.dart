import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/notifikasi/notifikasi-page.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuFooter extends StatefulWidget {
  const MenuFooter({super.key, required this.title});
  final String title;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
 
  @override
  State<MenuFooter> createState() => _MenuFooterState();
}

class _MenuFooterState extends State<MenuFooter> {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref();
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
    return Scaffold(
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
              NotifikasiPage(),
            ],
          ),
        ),
        
        bottomNavigationBar: _showBottomNavBar ? CurvedNavigationBar(
          backgroundColor:  const Color.fromARGB(255, 229, 229, 229),
          // buttonBackgroundColor: Colors.white,
          color: const Color.fromARGB(255, 229, 229, 229),
          height: 65,
          index: _currentIndex, // Tentukan indeks aktif
          items: <Widget>[
            _buildIconWithText(Icons.home, "Home", 0),
            _buildIconWithText(Icons.timer, "Riwayat", 1),
            _buildIconWithText(Icons.mail, "Izin", 2),
            _buildIconWithText(Icons.upload, "Pengajuan", 3),
          ],
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linearToEaseOut,
            );
            setState(() {
            _currentIndex = index;
            _showBottomNavBar = true;
          });
          },
        ) : null, 
    );
  }

  Widget _buildIconWithText(IconData icon, String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: _currentIndex == index
                  ? [
                      const Color.fromARGB(255, 50, 50, 50),
                      const Color.fromARGB(255, 31, 31, 31)
                    ] // Warna ungu gradian untuk ikon aktif
                  : [
                      Color.fromARGB(255, 188, 187, 187),
                      Color.fromARGB(255, 169, 169, 169),
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
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _currentIndex == index
                ? const Color.fromARGB(255, 50, 50, 50)
                : const Color.fromARGB(255, 150, 150, 150),
          ),
        ),
      ],
    );
  }
}
