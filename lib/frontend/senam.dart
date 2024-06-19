import 'package:flutter/material.dart';


class Senam extends StatefulWidget {
  const Senam({Key? key}) : super(key: key);

  @override
  State<Senam> createState() => _SenamState();
}

class _SenamState extends State<Senam> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senam'),
      ),
      body: const SingleChildScrollView(
        child: Center(),
      ),
    );
  }
}
