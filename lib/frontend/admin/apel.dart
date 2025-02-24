import 'package:flutter/material.dart';

class ApelAdmin extends StatefulWidget {
  const ApelAdmin({super.key});

  @override
  State<ApelAdmin> createState() => _ApelAdminState();
}

class _ApelAdminState extends State<ApelAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ApelAdmin'),
        ),
        body: Center(),
    );
  }
}