import 'package:flutter/material.dart';

class ListWifiAdmin extends StatefulWidget {
  const ListWifiAdmin({Key? key}) : super(key: key);

  @override
  State<ListWifiAdmin> createState() => _ListWifiAdminState();
}

class _ListWifiAdminState extends State<ListWifiAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ListWifiAdmin'),
        ),
        body: Center(),
    );
  }
}