import 'package:flutter/material.dart'; 

class CekIzin extends StatefulWidget {
  const CekIzin({super.key});

  @override
  State<CekIzin> createState() => _CekIzinState();
}

class _CekIzinState extends State<CekIzin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Izin'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/izin'); 
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
