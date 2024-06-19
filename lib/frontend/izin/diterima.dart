import 'package:flutter/material.dart';


class Terimaizin extends StatefulWidget {
    const Terimaizin({Key? key}) : super(key: key);


  @override
  State<Terimaizin> createState() => _TerimaizinState();
}

class _TerimaizinState extends State<Terimaizin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Izin Diterima'),
        ),
        body: const SingleChildScrollView());
  }
}
