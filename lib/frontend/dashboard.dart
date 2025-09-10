import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/izin/izin.dart';
import 'package:mobileabsensi/frontend/notifikasi/notifikasi-page.dart';
import 'package:mobileabsensi/screenshoot.dart';
import 'package:permission_handler/permission_handler.dart';

class Dashboard extends StatefulWidget {
  final int initialIndex;
  const Dashboard({super.key, required this.initialIndex});

  @override
  State<Dashboard> createState() => _DashboardState();
} 

class _DashboardState extends State<Dashboard> {
  final GlobalKey _screenshotKey = GlobalKey();
  late final PageController _pageController;
  late int _currentIndex;

  Offset _cameraPosition = Offset.zero;
  bool _isDragging = false;

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
    var storage = await Permission.storage.request();

    if (notificationStatus.isDenied) {
      notificationStatus = await Permission.notification.request();
    }

    if (locationStatus.isGranted &&
        wifiStatus.isGranted &&
        camera.isGranted &&
        galleryStatus.isGranted &&
        storage.isGranted &&
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
    // Inisialisasi posisi hanya sekali jika masih zero
    if (_cameraPosition == Offset.zero) {
      _cameraPosition = Offset(
        MediaQuery.of(context).size.width - 80, 
        MediaQuery.of(context).size.height * 0.5 - 30
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Konten utama
          RepaintBoundary(
            key: _screenshotKey,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
          
          // Tombol screenshot yang bisa digeser
          Positioned(
            left: _cameraPosition.dx,
            top: _cameraPosition.dy,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _cameraPosition += details.delta;
                  
                  // Batasi agar tidak keluar dari layar
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  
                  if (_cameraPosition.dx < 0) _cameraPosition = Offset(0, _cameraPosition.dy);
                  if (_cameraPosition.dx > screenWidth - 60) {
                    _cameraPosition = Offset(screenWidth - 60, _cameraPosition.dy);
                  }
                  if (_cameraPosition.dy < 0) _cameraPosition = Offset(_cameraPosition.dx, 0);
                  if (_cameraPosition.dy > screenHeight - 60) {
                    _cameraPosition = Offset(_cameraPosition.dx, screenHeight - 60);
                  }
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: Opacity(
                opacity: _isDragging ? 0.8 : 1.0,
                child: ScreenshotButton(
                  screenshotKey: _screenshotKey,
                  onScreenshotTaken: () {
                    print('Screenshot berhasil diambil dari Dashboard!');
                  },
                  onScreenshotSaved: (String? path) {
                    if (path != null) {
                      print('Screenshot disimpan di: $path');
                    }
                  },
                ),
              ),
            ),
          ),
        ],
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