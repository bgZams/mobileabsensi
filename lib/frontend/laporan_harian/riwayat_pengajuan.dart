import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobileabsensi/core.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class RiwayatPengajuanLhk extends StatefulWidget {
  const RiwayatPengajuanLhk({Key? key}) : super(key: key);

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
    initializePreferences();
  }

  Future<void> initializePreferences() async {
    url = SpUtil.getString("url");
    idUser = SpUtil.getString("id_user");
    if (idUser != null && url != null && idUser!.isNotEmpty && url!.isNotEmpty) {
      await _fetchData();
    } else {
      debugPrint('Error: idUser or url is empty');
    }
  }

  Future<void> _fetchData() async {
    try {
      final responseLhk = await http.get(
        Uri.parse('$url/api/riwayat-lhk/pengajuan/$idUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (responseLhk.statusCode == 200) {
        _processLhk(responseLhk);
      } else {
        debugPrint('Failed to load data Izin: ${responseLhk.statusCode}');
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
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Laporan Harian'),
        flexibleSpace: const Image(
          image: AssetImage('assets/images/bannernav.png'),
          fit: BoxFit.cover,
        ),
        leading: IconButton(
          iconSize: 30,
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
             Navigator.pop(context);
          },
        ),
      ),
      body: _riwayatLhk.isEmpty
          ? const Center(child: Text('No data found'))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _riwayatLhk.length,
                      itemBuilder: (context, index) =>
                          _buildLhkItem(context, _riwayatLhk[index]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLhkItem(BuildContext context, dynamic lhk) {
    return Card(
          color: const Color.fromARGB(255, 241, 251, 255),
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: ListTile(
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${lhk['tgl'].toString()}', style: const TextStyle(color: Colors.black),),
                Text('Jam Mulai: ${lhk['jammulai'].toString()}', style:const TextStyle(color: Colors.black),),
                Text('Jam Selesai: ${lhk['jamselesai'].toString()}', style:const TextStyle(color: Colors.black),),
                Text('Kegiatan: ${lhk['rincian_kegiatan']}', style:const TextStyle(color: Colors.black),),
              ],
            ),
        
            Column(children: [
              InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/edit_lhk', arguments: lhk);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 13, horizontal: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color.fromARGB(255, 167, 255, 171), // Changed color to indicate a different action
                ),
                child: const Icon(Icons.edit,color: Color.fromARGB(255, 0, 158, 8),),
              ),
            ),
            const SizedBox(height: 10,),
              InkWell(
              onTap: () {
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 13, horizontal: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color.fromARGB(255, 255, 160,
                      160), // Changed color to indicate a different action
                ),
                child: const Icon(Icons.delete,color: Color.fromARGB(255, 156, 0, 0),),
              ),
            ),
            ],),
          ],
        ),
      ),
    );
  }
}
