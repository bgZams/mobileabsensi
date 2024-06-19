import 'package:flutter/material.dart';


class TolakIzin extends StatefulWidget {
  const TolakIzin({Key? key}) : super(key: key);

  @override
  State<TolakIzin> createState() => _TolakIzinState();
}

class _TolakIzinState extends State<TolakIzin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Izin Ditolak'),
        ),
        body: const SingleChildScrollView());
  }
}
