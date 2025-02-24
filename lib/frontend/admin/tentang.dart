import 'package:flutter/material.dart';

class TentangAdmin extends StatefulWidget {
  const TentangAdmin({super.key});

  @override
  State<TentangAdmin> createState() => _TentangAdminState();
}

class _TentangAdminState extends State<TentangAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TentangAdmin'),
        ),
        body: Center(),
    );
  }
}