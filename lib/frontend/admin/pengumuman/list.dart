import 'package:flutter/material.dart';

class ListPengumuman extends StatefulWidget {
  const ListPengumuman({super.key});

  @override
  State<ListPengumuman> createState() => _ListPengumumanState();
}

class _ListPengumumanState extends State<ListPengumuman> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ListPengumuman'),
        ),
        body: Center(),
    );
  }
}