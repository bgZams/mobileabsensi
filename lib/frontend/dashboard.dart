import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/halaman/izin.dart';
import 'package:mobileabsensi/frontend/halaman/lhk.dart';
import 'package:mobileabsensi/frontend/izin/izin.dart';
import 'package:mobileabsensi/frontend/notifikasi/notifikasi-page.dart';
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

  // Warna Tema (Bisa disesuaikan dengan branding kampus/kantor)
  final Color _mainColor = const Color(0xFF4C6EF5); // Contoh: Royal Blue
  final Color _navBarColor = Colors.white;
  final Color _iconActiveColor = Colors.white;
  final Color _iconInactiveColor = Colors.grey.shade400;

  final List<Widget> _pages = const [
    Absen(),
    RiwayatAbsen(),
    IzinFront(),
    LhkFront(),
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

  Future<void> _requestPermissions() async {
    // ... (Kode permission tetap sama)
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.photos,
      Permission.notification
    ].request();
  }

  void _onNavTapped(int index) {
    _pageController.jumpToPage(index); 
    // Menggunakan jumpToPage lebih responsif untuk curved nav bar
    // daripada animateToPage yang kadang bentrok dengan animasi curve
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [PENTING] Ini membuat konten menyatu di belakang navbar
      extendBody: true, 
      backgroundColor: Colors.grey.shade100, // Warna background body
      
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),

      bottomNavigationBar: Theme(
        // Menghilangkan highlight effect default yang mengganggu
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        child: CurvedNavigationBar(
          // Kunci agar terlihat floating
          backgroundColor: Colors.transparent, 
          // Warna batang navigasi
          color: _navBarColor, 
          // Warna bola yang melayang (Active)
          buttonBackgroundColor: _mainColor, 
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          index: _currentIndex,
          onTap: _onNavTapped,
          items: [
            _buildNavItem(Icons.home_rounded, "Home", 0),
            _buildNavItem(Icons.history_rounded, "Riwayat", 1),
            _buildNavItem(Icons.mail_outline_rounded, "Izin", 2),
            _buildNavItem(Icons.upload_file_rounded, "LHK", 3),
          ],
        ),
      ),
    );
  }

  // Widget custom untuk mengatur logika tampilan icon
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 30,
          // Jika dipilih, warnanya putih (karena background bola biru)
          // Jika tidak, warnanya abu-abu
          color: isSelected ? _iconActiveColor : _iconInactiveColor,
        ),
        
        // UX TRICK: Hanya tampilkan teks jika TIDAK dipilih.
        // Saat dipilih, icon masuk ke dalam bola, teks disembunyikan agar rapi.
        if (!isSelected) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _iconInactiveColor,
            ),
          ),
        ]
      ],
    );
  }
}