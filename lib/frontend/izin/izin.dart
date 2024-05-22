import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:sp_util/sp_util.dart';

class Izin extends StatefulWidget {
  const Izin({Key? key}) : super(key: key);

  @override
  State<Izin> createState() => _IzinState();
}

class _IzinState extends State<Izin> {
  var url = SpUtil.getString("url");
  late Future<List<Map<String, dynamic>>> _futureData;
  bool _isLoading = false;
  late String selectedYear = '';
  late String selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    _futureData = fetchData(selectedMonth, selectedYear);
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

  Future<List<Map<String, dynamic>>> fetchData(
      String selectedMonth, String selectedYear) async {
    try {
      String selectedMonthNumber = _getMonthNumber(selectedMonth);
      final idUser = SpUtil.getString("id_user");
      final response = await http.get(Uri.parse(
          '$url/api/riwayat-izin/$idUser/$selectedMonthNumber/$selectedYear'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body)['data'];
        _isLoading = false;
        return responseData.cast<Map<String, dynamic>>();
      } else {
        _isLoading = false;
        throw Exception('Failed to load data');
      }
    } catch (e) {
      _isLoading = false;
      throw Exception('Tidak dapat terhubung ke server');
    }
  }

  void cariData(String selectedMonth, String selectedYear) {
    setState(() {
      _futureData = fetchData(selectedMonth, selectedYear);
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _futureData = fetchData(selectedMonth, selectedYear);
      _isLoading = false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text(' :: Riwayat Izin'),
        elevation: 4,
      ),
      body: SizedBox(
        height: deviceHeight * 1.2,
        child: Container(
          color: const Color.fromARGB(255, 238, 238, 238),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const BuatIzin()),
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
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                  cariData(selectedMonth, selectedYear);
                                },
                                child: const Text('Cari'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _futureData,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    children: [
                                      Card(
                                        color: const Color.fromARGB(
                                            255, 253, 247, 247),
                                        child: DataTable(
                                          columns: const <DataColumn>[
                                            DataColumn(label: Text('Tgl')),
                                            DataColumn(label: Text('Status')),
                                            DataColumn(label: Text('Durasi')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: snapshot.data!
                                              .map<DataRow>((data) {
                                            IconData iconData;
                                            Color iconColor;
                                            Text jenisStatus;

                                            switch (data['status_approval']
                                                .toString()) {
                                              case '1':
                                                iconData =
                                                    FontAwesomeIcons.stopwatch;
                                                iconColor = Colors.orange;
                                                break;
                                              case '2':
                                                iconData = Icons.check_outlined;
                                                iconColor = Colors.green;
                                                break;
                                              case '3':
                                                iconData = Icons.close;
                                                iconColor = Colors.red;
                                                break;
                                              default:
                                                iconData = Icons.error;
                                                iconColor = Colors.black;
                                            }

                                            switch (data['jenis_approval']
                                                .toString()) {
                                              case '2':
                                                jenisStatus =
                                                    const Text('Dinas Luar');
                                                break;
                                              case '3':
                                                jenisStatus =
                                                    const Text('Izin');
                                                break;
                                              case '4':
                                                jenisStatus =
                                                    const Text('Sakit');
                                                break;
                                              case '5':
                                                jenisStatus =
                                                    const Text('IDLK');
                                                break;
                                              case '6':
                                                jenisStatus =
                                                    const Text('Cuti');
                                                break;
                                              default:
                                                jenisStatus = const Text(
                                                    'Belum Disetujui');
                                            }

                                            return DataRow(
                                                cells: [
                                                  DataCell(
                                                      Text(data['tgl_mulai'])),
                                                  DataCell(jenisStatus),
                                                  DataCell(Text(data['durasi']
                                                      .toString())),
                                                  DataCell(
                                                    Icon(
                                                      iconData,
                                                      color: iconColor,
                                                    ),
                                                  ),
                                                ],

// Di dalam builder DataTable, gunakan fungsi navigateToDetailPage
                                                onSelectChanged: (selected) {
                                                  if (selected != null &&
                                                      selected) {
                                                    navigateToDetailPage(
                                                        data,
                                                        data[
                                                            'no_urut']); // Gunakan data['no_urut'] untuk mendapatkan nomor urut
                                                  }
                                                });
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void navigateToDetailPage(Map<String, dynamic> data, int noUrut) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPengajuanIzin(
          data: data,
          noUrut: noUrut,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(currentYear - 2020 + 1, (index) {
      return (2020 + index).toString();
    });

    return years.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }
}
