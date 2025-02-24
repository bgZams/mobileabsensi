import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/widget/bulan.dart';

class LhkPage extends StatefulWidget {
  final String idPegawai;

  const LhkPage({super.key, required this.idPegawai});

  @override
  State<LhkPage> createState() => _LhkPageState();
}

class _LhkPageState extends State<LhkPage> {
  Map<String, List<dynamic>> groupedLhk = {};
  late String selectedYear;
  late String selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    fetchLhk();
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[month - 1];
  }

  String getMonthNumber(String monthName) {
    const monthNumbers = {
      'Januari': '01', 'Februari': '02', 'Maret': '03', 'April': '04',
      'Mei': '05', 'Juni': '06', 'Juli': '07', 'Agustus': '08',
      'September': '09', 'Oktober': '10', 'November': '11', 'Desember': '12'
    };
    return monthNumbers[monthName] ?? '01';
  }

  Future<void> fetchLhk() async {
    final response = await http.get(
      Uri.parse('http://mobileabsensi1.pasamanbaratkab.go.id/api_android/web/riwayat_lhk.php?nama_bulan=05&id_user=${widget.idPegawai}&tahun=2024'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List<dynamic> lhkData = jsonResponse['data'];
      setState(() {
        groupedLhk = {};
        for (var entry in lhkData) {
          String date = entry['tgl'];
          if (!groupedLhk.containsKey(date)) {
            groupedLhk[date] = [];
          }
          groupedLhk[date]!.add(entry);
        }

        groupedLhk.forEach((date, activities) {
          activities.sort((a, b) => a['jammulai'].compareTo(b['jammulai']));
        });
      });
    } else {
      throw Exception('Failed to load LHK data');
    }
  }

  void _cariData(String selectedMonth, String selectedYear) async {
    setState(() {
      // _isLoading = true;
    });

    try {
      String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
      http.Response response = await http.get(
        Uri.parse(
          'http://mobileabsensi1.pasamanbaratkab.go.id/api_android/web/riwayat_lhk.php?nama_bulan=$selectedMonthNumber&id_user=${widget.idPegawai}&tahun=$selectedYear',
        ),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
          List<dynamic> lhkData = jsonResponse['data'];
          setState(() {
            groupedLhk = {};
            for (var entry in lhkData) {
              String date = entry['tgl'];
              if (!groupedLhk.containsKey(date)) {
                groupedLhk[date] = [];
              }
              groupedLhk[date]!.add(entry);
            }

            groupedLhk.forEach((date, activities) {
              activities.sort((a, b) => a['jammulai'].compareTo(b['jammulai']));
            });
          });
      } else {
        throw Exception('Kesalahan HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat hariFormat = DateFormat('EEEE', 'id_ID');
    final DateFormat tanggalFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('LHK Pegawai'),
      ),
      body: groupedLhk.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DropdownButton<String>(
                                    value: selectedMonth,
                                    hint: const Text('Pilih Bulan'),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedMonth = newValue!;
                                      });
                                    },
                                    items: [
                                      'Januari',
                                      'Februari',
                                      'Maret',
                                      'April',
                                      'Mei',
                                      'Juni',
                                      'Juli',
                                      'Agustus',
                                      'September',
                                      'Oktober',
                                      'November',
                                      'Desember'
                                    ].map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(width: 16),
                                  // Inputan Tahun
                                  DropdownButton<String>(
                                    value: selectedYear,
                                    hint: const Text('Pilih Tahun'),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedYear = newValue!;
                                      });
                                    },
                                    items: _getYearItems(),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      _cariData(selectedMonth, selectedYear);
                                    },
                                    child: const Text('Cari'),
                                  ),
                                ],
                              ),
              Expanded(
                child: ListView.builder(
                    itemCount: groupedLhk.keys.length,
                    itemBuilder: (context, index) {
                      String date = groupedLhk.keys.elementAt(index);
                      List<dynamic> activities = groupedLhk[date]!;
                
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hariFormat.format(DateTime.parse(date))}, ${tanggalFormat.format(DateTime.parse(date))}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...activities.map((activity) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mulai ${activity['jammulai'].substring(0, 5)} - Selesai ${activity['jamselesai'].substring(0, 5)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(activity['rincian_kegiatan']),
                                    ],
                                  ),
                                );
                              }),
                            ],
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
  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) {
      return DropdownMenuItem<String>(
        value: (2018 + index).toString(),
        child: Text((2018 + index).toString()),
      );
    });
  }
}
