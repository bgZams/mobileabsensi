import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/laporan_harian/riwayat_pengajuan.dart';
import 'package:sp_util/sp_util.dart';

class LaporanHarian extends StatefulWidget {
  const LaporanHarian({Key? key}) : super(key: key);

  @override
  State<LaporanHarian> createState() => _LaporanHarianState();
}

class _LaporanHarianState extends State<LaporanHarian> {
  var url = SpUtil.getString("url");
  List<DataRow> _rows = [];
  bool _isLoading = true;
  late String selectedYear = '';
  late String selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    _fetchData();
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    ];
    return monthNames[month - 1];
  }

  String _getMonthNumber(String monthName) {
    const monthNames = {
      'Januari': '01',
      'Februari': '02',
      'Maret': '03',
      'April': '04',
      'Mei': '05',
      'Juni': '06',
      'Juli': '07',
      'Agustus': '08',
      'September': '09',
      'Oktober': '10',
      'November': '11',
      'Desember': '12'
    };
    return monthNames[monthName] ?? '01';
  }

  Future<void> _fetchData() async {
    final idUser = SpUtil.getString("id_user");
    String selectedMonthNumber = _getMonthNumber(selectedMonth);
    if (idUser != null) {
      try {
        final dataLaporanHarian = await http.get(
          Uri.parse(
              '$url/api/riwayat_lhk/$idUser/$selectedMonthNumber/$selectedYear'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (dataLaporanHarian.statusCode == 200) {
          final jsonData =
              jsonDecode(dataLaporanHarian.body) as Map<String, dynamic>;
          if (jsonData.containsKey('data')) {
            final dataList = jsonData['data'] as List<dynamic>;
            setState(() {
              _rows = dataList.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['tgl'])),
                    DataCell(Text(data['jammulai'])),
                    DataCell(Text(data['jamselesai'])),
                    DataCell(Text(data['rincian_kegiatan'])),
                    DataCell(Text(data['status'])),
                  ],
                );
              }).toList();
              _isLoading = false;
            });
          } else {
            throw Exception('Gagal mengambil data');
          }
        } else {
          throw Exception('Kesalahan HTTP: ${dataLaporanHarian.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          throw Exception('Tidak dapat terhubung ke server');
        }
      }
    }
  }

  void _cariData(String selectedMonth, String selectedYear) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String selectedMonthNumber = _getMonthNumber(selectedMonth);
      var idUser = SpUtil.getString("id_user");
      http.Response riwayatLaporanHarian = await http.get(
        Uri.parse(
          '$url/api/riwayat_lhk/$idUser/$selectedMonthNumber/$selectedYear',
        ),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (riwayatLaporanHarian.statusCode == 200) {
        final jsonData =
            jsonDecode(riwayatLaporanHarian.body) as Map<String, dynamic>;
        if (jsonData.containsKey('data')) {
          final dataList = jsonData['data'] as List<dynamic>;
          setState(() {
            _rows = dataList.map((data) {
              return DataRow(
                cells: [
                  DataCell(Text(data['tgl'])),
                  DataCell(Text(data['jammulai'])),
                  DataCell(Text(data['jamselesai'])),
                  DataCell(Text(data['rincian_kegiatan'])),
                  DataCell(Text(data['status'])),
                ],
              );
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Gagal mengambil data');
        }
      } else {
        throw Exception('Kesalahan HTTP: ${riwayatLaporanHarian.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCards() {
    // Membuat map untuk mengelompokkan item berdasarkan tanggal
    Map<String, List<DataRow>> groupedData = {};

    // Mengelompokkan data rows berdasarkan tanggal
    for (var dataRow in _rows) {
      final tanggal = (dataRow.cells[0].child as Text).data as String;
      if (!groupedData.containsKey(tanggal)) {
        groupedData[tanggal] = [];
      }
      groupedData[tanggal]?.add(dataRow);
    }

    // Membangun card-card untuk setiap tanggal
    List<Widget> cards = [];
    groupedData.forEach((tanggal, dataRows) {
      List<Widget> rowWidgets = [];

      for (var dataRow in dataRows) {
        final cells = dataRow.cells.toList();
        final jamMulai = (cells[1].child as Text).data as String;
        final jamSelesai = (cells[2].child as Text).data as String;
        final kegiatan = (cells[3].child as Text).data as String;
        final status = (cells[4].child as Text).data as String;

        IconData statusIcon;
        Color statusColor;

        if (status == '1') {
          statusIcon = Icons.sync;
          statusColor = const Color.fromARGB(255, 255, 196, 0);
        } else if (status == '2') {
          statusIcon = Icons.check;
          statusColor = Colors.red;
        } else if (status == '3') {
          statusIcon = Icons.close;
          statusColor = Colors.red;
        } else if (status == '4') {
          statusIcon = Icons.miscellaneous_services_rounded;
          statusColor = const Color.fromARGB(255, 0, 193, 190);
        } else {
          statusIcon = Icons.error;
          statusColor = const Color.fromARGB(255, 255, 37, 37);
        }

        // Menambahkan widget informasi ke dalam rowWidgets
        rowWidgets.add(
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.access_time,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        jamMulai,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 147, 125, 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_outlined,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        jamSelesai,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 74, 120, 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundColor: statusColor,
                      radius: 12,
                      child: Icon(
                        statusIcon,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    kegiatan,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Divider(
                // Menambahkan garis di antara card
                color: Colors.grey,
                thickness: 1,
              ),
            ],
          ),
        );
      }

      // Membuat card dengan data yang dikelompokkan
      cards.add(
        Card(
          margin: const EdgeInsets.all(8),
          color: const Color.fromARGB(255, 245, 242, 242),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tanggal: $tanggal',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: rowWidgets,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Column(
      children: cards,
    );
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _fetchData();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian'),
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: 1 + _rows.length, // ditambah 1 untuk teks 'data'
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      color: const Color.fromARGB(31, 136, 183, 255),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.only(left: 30),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const BuatLaporan()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 0, 110, 255),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('+ Izin',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.only(left: 30),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RiwayatPengajuanLhk()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 230, 211, 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Diajukan',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
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
                              // Tombol Cari
                              ElevatedButton(
                                onPressed: () {
                                  _cariData(selectedMonth, selectedYear);
                                },
                                child: const Text('Cari'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ); // Teks di atas daftar
                  } else {
                    return Container(
                        color: const Color.fromARGB(255, 238, 238, 238),
                        child: _buildCards());
                  }
                },
              ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(currentYear - 2018 + 1, (index) {
      return (2018 + index).toString();
    });

    return years.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }
}
