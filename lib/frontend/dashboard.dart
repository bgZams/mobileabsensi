import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/izin/izin.dart';
import 'package:mobileabsensi/frontend/notifikasi/notifikasi-page.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class Dashboard extends StatefulWidget {
  final int initialIndex;
  const Dashboard({super.key, required this.initialIndex});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final PageController _pageController;
  late int _currentIndex;

  final List<Widget> _pages = const [
    Absen(),
    RiwayatAbsen(),
    Izin(),
    NotifikasiPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _requestPermissions();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.linearToEaseOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(255, 229, 229, 229),
        color: const Color.fromARGB(255, 229, 229, 229),
        height: 65,
        index: _currentIndex,
        onTap: _onNavTapped,
        items: [
          _buildIconWithText(Icons.home, "Home", 0),
          _buildIconWithText(Icons.timer, "Riwayat", 1),
          _buildIconWithText(Icons.mail, "Izin", 2),
          _buildIconWithText(Icons.upload, "Pengajuan", 3),
        ],
      ),
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
                      Color.fromARGB(255, 50, 50, 50),
                      Color.fromARGB(255, 31, 31, 31),
                    ]
                  : [
                      Color.fromARGB(255, 139, 139, 139),
                      Color.fromARGB(255, 113, 113, 113),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds);
          },
          child: Icon(
            icon,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _currentIndex == index
                ? Color.fromARGB(255, 50, 50, 50)
                : Color.fromARGB(255, 150, 150, 150),
          ),
        ),
      ],
    );
  }
}
