import 'package:flutter/material.dart';

class Homeku extends StatefulWidget {
  const Homeku({super.key});

  @override
  State<Homeku> createState() => _HomekuState();
}

class _HomekuState extends State<Homeku> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: const SingleChildScrollView());
  }
}
