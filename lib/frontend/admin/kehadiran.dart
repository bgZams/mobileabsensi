import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sp_util/sp_util.dart';
import 'package:url_launcher/url_launcher.dart';

class Kehadiran extends StatefulWidget {
  const Kehadiran({super.key});

  @override
  State<Kehadiran> createState() => _KehadiranState();
}

class _KehadiranState extends State<Kehadiran> {
  List<dynamic> users = [];
  String idUser = SpUtil.getString('id_user')!;
  String url = SpUtil.getString('url')!;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool noDataFound = false;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = dateFormat.format(selectedDate);
    _fetchKehadiran();
  }

  Future<void> _fetchKehadiran() async {
    _cariData(dateFormat.format(selectedDate));
  }

  Future<void> _cariData(String tanggal) async {
    setState(() {
      isLoading = true;
      noDataFound = false;
    });

    final response = await http.get(
      Uri.parse('$url/api/admin/kehadiran/$idUser/$tanggal'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body)["data"];
      if (jsonData.isEmpty) {
        setState(() {
          noDataFound = true;
          users.clear();
        });
      } else {
        setState(() {
          users = jsonData;
        });
      }
    } else {
      throw Exception('Failed to load attendance data');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = dateFormat.format(selectedDate);
        _cariData(dateFormat.format(selectedDate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kehadiran Pegawai'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : noDataFound
              ? const Center(child: Text('Data tidak ditemukan'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Pilih Tanggal',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          Color statusColor;
                          switch (user['status']) {
                            case 'HADIR':
                              statusColor = Colors.green;
                              break;
                            case 'DINAS LUAR':
                              statusColor = Colors.blue;
                              break;
                            case 'IZIN':
                              statusColor = Colors.yellow;
                              break;
                            case 'SAKIT':
                              statusColor = Colors.red;
                              break;
                            case 'IDLK':
                              statusColor = Colors.purple;
                              break;
                            case 'CUTI':
                              statusColor = Colors.orange;
                              break;
                            default:
                              statusColor = Colors.white;
                          }
                          return Card(
                            child: ListTile(
                              title: Text(user['nama_lengkap']),
                              subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${user['timestamp_masuk'].toString()} - ${user['timestamp_pulang'].toString()}'),
                                  SizedBox(
                                    width: 60,
                                    height: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: statusColor,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        user['status'],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(user['nama_lengkap']),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Tanggal Absen: ${user['tgl_absen']}'),
                                            if (user['status'] == 'HADIR')
                                              Column(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Jam Masuk: ${user['timestamp_masuk']}'),
                                                  Text('SSID: ${user['SSID']}'),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                      'Jam Pulang: ${user['timestamp_pulang']}'),
                                                  Text(
                                                      'SSID: ${user['SSID_pulang']}'),
                                                ],
                                              ),
                                            if (user['status'] != 'HADIR')
                                              Column(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Jenis Cuti: ${user['jenis_cuti']}'),
                                                  InkWell(
                                                    onTap: () => canLaunchUrl(user['file']),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Text(
                                                        'Lihat Foto',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Tutup'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
