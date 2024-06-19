import 'package:flutter/material.dart';


class EditIzin extends StatefulWidget {
  const EditIzin({Key? key}) : super(key: key);

  @override
  State<EditIzin> createState() => _EditIzinState();
}

class _EditIzinState extends State<EditIzin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
      ),
      body: const SingleChildScrollView(
        child: Column(children: []),
      ),
      // bottomNavigationBar: _showBottomNav(),
    );
  }
}
