import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/absen/laporan_harian.dart';
import 'package:mobileabsensi/frontend/absen/shift.dart';
import 'package:mobileabsensi/frontend/halaman/izin.dart';
import 'package:mobileabsensi/frontend/halaman/lhk.dart';
import 'package:mobileabsensi/presentation/widgets/screen_wrapper.dart'; 
import 'package:mobileabsensi/frontend/admin/absen.dart';
import 'package:mobileabsensi/frontend/admin/detail_pegawai.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';
import 'package:mobileabsensi/frontend/admin/lhk.dart';
import 'package:mobileabsensi/frontend/absen/absen.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/auth/login_first.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/frontend/izin/detail_konfirmasi_atasan.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/laporan_harian/buat.dart';
import 'package:mobileabsensi/frontend/laporan_harian/riwayat_pengajuan.dart';
import 'package:mobileabsensi/frontend/laporan_harian/status.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:mobileabsensi/frontend/profile.dart';
import 'package:mobileabsensi/frontend/senam.dart';
import 'package:mobileabsensi/frontend/absen/riwayat_absen.dart';
import 'package:mobileabsensi/frontend/izin/buat.dart';
// import 'package:mobileabsensi/singgah.dart';
import 'package:mobileabsensi/frontend/teknis/pending_wifi.dart';

/// Fungsi helper untuk membungkus halaman dengan ScreenWrapper dan mengembalikannya sebagai Route.
/// Fungsi ini digunakan khusus untuk onGenerateRoute yang membutuhkan tipe pengembalian Route.
Route<dynamic> buildPageRoute(Widget page) {
  return MaterialPageRoute(builder: (context) => ScreenWrapper(child: page));
}

/// Daftar rute statis aplikasi.
/// Setiap builder harus mengembalikan sebuah Widget.
final Map<String, WidgetBuilder> appRoutes = {
  '/login-first': (context) => ScreenWrapper(child: const LoginFirst()),
  '/login': (context) => ScreenWrapper(child: const Login()),
  '/absen': (context) => ScreenWrapper(child: const Absen()),
  '/shift': (context) => ScreenWrapper(child: const Shift()),
  '/dashboard': (context) => ScreenWrapper(child: Dashboard(initialIndex: 0)),
  '/absen-masuk': (context) => ScreenWrapper(child: const Absen()),
  '/profil': (context) => ScreenWrapper(child: const Profile()),
  '/riwayat': (context) => ScreenWrapper(child: const RiwayatAbsen()),
  // '/laporan': (context) => ScreenWrapper(child: const Laporan()),
  '/laporan': (context) => ScreenWrapper(child: const LhkFront()),
  '/create-laporan': (context) => ScreenWrapper(child: const BuatLaporan()),
  '/riwayat-laporan': (context) => ScreenWrapper(child: const LaporanHarian()),
  '/riwayat-laporan/pengajuan': (context) => ScreenWrapper(child: const RiwayatPengajuanLhk()),
  '/status-laporan': (context) => ScreenWrapper(child: const StatusLaporan()),
  // '/izin': (context) => ScreenWrapper(child: const Izin()),
  '/izin': (context) => ScreenWrapper(child: const IzinFront()),
  '/buat_izin': (context) => ScreenWrapper(child: const BuatIzin()),
  '/konfirmasi-izin': (context) => ScreenWrapper(child: const KonfirmasiIzin()),
  '/detail-konfirmasi-izin': (context) => ScreenWrapper(child: const DetailKonfirmasiIzinAtasan()),
  '/apel': (context) => ScreenWrapper(child: const Apel()),
  '/senam': (context) => ScreenWrapper(child: const Senam()),
  '/pengumuman': (context) => ScreenWrapper(child: const Pengumuman()),
  '/wifi/pending': (context) => ScreenWrapper(child: const WifiPendding()),
  '/admin': (context) => ScreenWrapper(child: const Admin()),
};

/// Fungsi untuk menangani rute dinamis (misalnya dengan ID).
/// Fungsi ini harus mengembalikan sebuah Route.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
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
    if (page != null) {
      // Di sini kita menggunakan helper yang mengembalikan Route
      return buildPageRoute(page);
    }
  }
  return null;
}