import 'package:flutter/material.dart';

class KendalaAbsen extends StatefulWidget {
  const KendalaAbsen({super.key});

  @override
  State<KendalaAbsen> createState() => _KendalaAbsenState();
}

class _KendalaAbsenState extends State<KendalaAbsen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendala Absen'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}