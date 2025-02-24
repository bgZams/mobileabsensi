import 'package:flutter/material.dart';


class StatusIzin extends StatefulWidget {
  const StatusIzin({super.key});

  @override
  State<StatusIzin> createState() => _StatusIzinState();
}

class _StatusIzinState extends State<StatusIzin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Status Izin'),
        ),
        body: const SingleChildScrollView());
  }
}
