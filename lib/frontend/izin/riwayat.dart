import 'package:flutter/material.dart'; 

class RiwayatIzin extends StatefulWidget {
  const RiwayatIzin({Key? key}) : super(key: key);

  @override
  State<RiwayatIzin> createState() => _RiwayatIzinState();
}

class _RiwayatIzinState extends State<RiwayatIzin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Riwayat Izin'),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
      ),
        body: const SingleChildScrollView());
  }
}
