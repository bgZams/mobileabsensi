import 'package:flutter/material.dart';


class KonfirmasiLaporanHarian extends StatefulWidget {
  const KonfirmasiLaporanHarian({super.key});

  @override
  State<KonfirmasiLaporanHarian> createState() =>
      _KonfirmasiLaporanHarianState();
}

class _KonfirmasiLaporanHarianState extends State<KonfirmasiLaporanHarian> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Laporan Harian'),
      ),
      body: const SingleChildScrollView(
        child: Center(),
      ),
    );
  }
}
