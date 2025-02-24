import 'package:flutter/material.dart';

class BeritaAdmin extends StatefulWidget {
  const BeritaAdmin({super.key});

  @override
  State<BeritaAdmin> createState() => _BeritaAdminState();
}

class _BeritaAdminState extends State<BeritaAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Berita'),
        ),
        body: Center(),
    );
  }
}