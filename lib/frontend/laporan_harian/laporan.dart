import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/laporan_harian/buat.dart';

import '../absen/laporan_harian.dart';

class Laporan extends StatefulWidget {
  const Laporan({super.key});

  @override
  State<Laporan> createState() => _LaporanState();
}

class _LaporanState extends State<Laporan> {
  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian'),
      ),
      body: SizedBox(
        height: deviceHeight * 1.2,
        child: Container(
          color: const Color.fromARGB(255, 238, 238, 238),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildButton('Buat Laporan', Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const BuatLaporan(),
                    ),
                  );
                }),
                _buildButton('Riwayat', Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const LaporanHarian(),
                    ),
                  );
                }),
                _buildButton('Diterima', Colors.green, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const LaporanHarian(),
                    ),
                  );
                }),
                _buildButton('Ditolak', Colors.red, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const LaporanHarian(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(1.0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(0, 3), // Ubah offset sesuai kebutuhan Anda
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
