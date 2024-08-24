import 'package:flutter/material.dart';

class Pegawai extends StatefulWidget {
  const Pegawai({Key? key}) : super(key: key);

  @override
  State<Pegawai> createState() => _PegawaiState();
}

class _PegawaiState extends State<Pegawai> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pegawai'),
        ),
        body: Center(),
    );
  }
}