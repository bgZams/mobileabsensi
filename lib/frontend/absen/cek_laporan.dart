import 'package:flutter/material.dart'; 

class CekLaporan extends StatefulWidget {
  const CekLaporan({Key? key}) : super(key: key);

  @override
  State<CekLaporan> createState() => _CekLaporanState();
}

class _CekLaporanState extends State<CekLaporan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Laporan'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home-page'); 
          },
        ),
      ),
      body: const SingleChildScrollView(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: []),
      ),
      // bottomNavigationBar: _showBottomNav(),
    );
  }
}
