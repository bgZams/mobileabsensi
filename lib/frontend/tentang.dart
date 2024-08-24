import 'package:flutter/material.dart';
import 'package:sp_util/sp_util.dart';

class Tentang extends StatefulWidget {
  const Tentang({Key? key}) : super(key: key);

  @override
  State<Tentang> createState() => _TentangState();
}

class _TentangState extends State<Tentang> {

  @override
  void initState() {
    super.initState();
    // You can initialize or fetch data here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text(
          'Tentang Absen Online',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentang Absen Online',
            ),
            SizedBox(height: 16.0),
            Text(
              'Absen Online adalah sistem digital yang memungkinkan karyawan untuk melakukan pencatatan kehadiran secara online. Sistem ini dirancang untuk menggantikan metode absensi tradisional seperti kartu absensi atau buku catatan, dengan memanfaatkan teknologi internet untuk memudahkan proses pencatatan kehadiran. Dengan memanfaatkan jaringan WIFI instansi, Absen Online memastikan bahwa pencatatan kehadiran dilakukan di lingkungan yang aman dan terkendali.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16.0),
            Text(
              'Fitur Utama:',
            ),
            SizedBox(height: 8.0),
            Text(
              '1. **Absensi Melalui Jaringan WIFI Instansi:**\n'
              '- **Keamanan Data:** Absen Online menggunakan jaringan WIFI instansi untuk memastikan bahwa data absensi dikumpulkan dalam lingkungan yang aman dan terkendali. Hal ini membantu mencegah akses tidak sah dan mengurangi risiko data absensi dicuri atau dimanipulasi.\n'
              '- **Akses Terbatas:** Dengan melakukan absensi melalui jaringan WIFI instansi, sistem dapat memastikan bahwa pencatatan kehadiran hanya dilakukan di area yang telah ditentukan, seperti kantor atau lokasi kerja, dan mencegah absensi palsu dari luar area tersebut.\n\n'
              '2. **Pemantauan dan Pengelolaan Kehadiran:**\n'
              '- **Rekaman Waktu:** Sistem mencatat waktu absensi secara otomatis dan real-time. Hal ini memastikan bahwa semua kehadiran tercatat dengan akurat dan dapat dipantau secara langsung.\n'
              '- **Laporan Kehadiran:** Fitur ini menyediakan laporan lengkap mengenai kehadiran karyawan, termasuk jumlah hari hadir, telat, izin, dan cuti. Laporan ini bisa diakses oleh manajer atau HRD untuk memudahkan proses evaluasi dan pengelolaan karyawan.\n\n'
              '3. **Notifikasi dan Peringatan:**\n'
              '- **Peringatan Absensi:** Sistem dapat mengirimkan notifikasi kepada karyawan mengenai waktu absensi yang akan datang atau pengingat jika karyawan belum melakukan absensi pada waktu yang ditentukan.\n'
              '- **Peringatan Keterlambatan:** Jika karyawan terlambat melakukan absensi, sistem dapat mengirimkan peringatan atau notifikasi kepada mereka untuk mengurangi kemungkinan keterlambatan berulang.\n\n'
              '4. **Integrasi dengan Sistem Manajemen:**\n'
              '- **Sinkronisasi Data:** Absen Online dapat terintegrasi dengan sistem manajemen karyawan lainnya, seperti sistem penggajian dan manajemen waktu, untuk memastikan bahwa data absensi diperbarui secara otomatis dan akurat.\n'
              '- **Pelaporan:** Fitur ini memungkinkan perusahaan untuk menghasilkan laporan yang relevan untuk analisis kehadiran, perhitungan gaji, dan penilaian kinerja.\n\n'
              '5. **Fleksibilitas dan Kemudahan Penggunaan:**\n'
              '- **Antarmuka Pengguna yang Intuitif:** Absen Online dirancang dengan antarmuka yang mudah digunakan, memungkinkan karyawan untuk melakukan absensi dengan beberapa klik saja menggunakan perangkat seluler atau komputer.\n'
              '- **Fleksibilitas Lokasi:** Meskipun pencatatan absensi dilakukan melalui jaringan WIFI instansi, sistem ini memungkinkan akses yang mudah bagi karyawan yang berada di area yang ditentukan.',
              
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
