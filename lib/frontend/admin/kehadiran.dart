import 'package:flutter/material.dart';

class Kehadiran extends StatefulWidget {
  const Kehadiran({Key? key}) : super(key: key);

  @override
  State<Kehadiran> createState() => _KehadiranState();
}

class _KehadiranState extends State<Kehadiran> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kehadiran'),
        ),
        body: Center(),
    );
  }
}