import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sp_util/sp_util.dart';
import 'package:table_calendar/table_calendar.dart';

class Kehadiran extends StatefulWidget {
  const Kehadiran({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _fetchKehadiran();
  }

  Future<void> _fetchKehadiran() async {
    _cariData(DateFormat('yyyy-MM-dd').format(selectedDate));
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
                    TableCalendar(
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(selectedDate, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          selectedDate = selectedDay;
                        });
                        _cariData(DateFormat('yyyy-MM-dd').format(selectedDate));
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Card(
                            child: ListTile(
                              title: Text(user['nama_lengkap']),
                              subtitle: Text(
                                '${user['timestamp_masuk'] ?? 'N/A'} - ${user['timestamp_pulang'] ?? 'N/A'}',
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
                                          children: [
                                            Text('Tanggal Absen: ${user['tgl_absen']}'),
                                            Text('Status Absen: ${user['status']}'),
                                            Text('Jenis Cuti: ${user['jenis_cuti']}'),
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
