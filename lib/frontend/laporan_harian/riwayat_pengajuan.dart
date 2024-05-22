import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class RiwayatPengajuanLhk extends StatefulWidget {
  const RiwayatPengajuanLhk({super.key});

  @override
  State<RiwayatPengajuanLhk> createState() => _RiwayatPengajuanLhkState();
}
  
class _RiwayatPengajuanLhkState extends State<RiwayatPengajuanLhk> {
  List<dynamic> _riwayatLhk = [];
  String? url;
  String? idUser;
@override
  void initState() {
    super.initState(); 
      _fetchData();
 
    initializePreferences();
  }

  Future<void> initializePreferences() async {
    await SpUtil.getInstance();
    setState(() {
      url = SpUtil.getString("url");
      idUser = SpUtil.getString("id_user");
    });
    _fetchData();
  }
Future<void> _fetchData() async {
    if (idUser == null || url == null || idUser!.isEmpty || url!.isEmpty) {
      debugPrint('Error: idUser or url is empty');
      return;
    }

    try {
      final responseIzin = await http.get(
        Uri.parse('$url/api/riwayat-izin/notif/$idUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final responseLhk = await http.get(
        Uri.parse('$url/api/riwayat-lhk/notif/$idUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (responseIzin.statusCode == 200) {
        _processLhk(responseIzin);
      } else {
        throw Exception('Failed to load data Izin');
      } 
    } catch (error) {
      debugPrint('Error: $error');
    }
  }
  void _processLhk(http.Response response) {
    setState(() {
      _riwayatLhk = json.decode(response.body)['data'];
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _fetchData();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Laporan Harian'),
      ),
      body: Column(children: [
        _riwayatLhk.isEmpty
              ? const Center(child: Text('No data found'))
              : ListView.builder(
                  itemCount: _riwayatLhk.length,
                  itemBuilder: (context, index) =>
                      _buildLhkItem(context, _riwayatLhk[index]),
                ),

      ]),
    );
  }


Widget _buildLhkItem(BuildContext context, dynamic lhk) {

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: ListTile(
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Ubah alignment menjadi sebelah kiri
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Ubah alignment menjadi sebelah kiri
                  children: [
                    Text('Jam Mulai: ${lhk['jammulai'].toString()}'),
                    Text('Jam Selesai: ${lhk['jamselesai'].toString()}'),
                    Text('Kegiatan: ${lhk['rincian_kegiatan']}'),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
],
        ),
      ),
    );
  }


}