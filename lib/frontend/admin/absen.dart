import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/absen/lihat_spt.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/services/refresh.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:sp_util/sp_util.dart';

class AbsenPage extends StatefulWidget {
  final String idPegawai;

  const AbsenPage({super.key, required this.idPegawai});

  @override
  AbsenPageState createState() => AbsenPageState();
}

class AbsenPageState extends State<AbsenPage> {
  var url = SpUtil.getString("url");
  List<DataRow> _rows = [];
  bool _isLoading = true;
  String selectedYear = '';
  String selectedMonth = '';
  DateTime? lastFetchTime;
  int syncCount = 0;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    _fetchData();
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[month - 1];
  }

  Future<void> _fetchData() async {
    if (mounted) {
      try {
        String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
        var idUser = widget.idPegawai;
        http.Response riwayatAbsen = await http.get(
          Uri.parse(
              '$url/api/riwayat-absen/$idUser/$selectedMonthNumber/$selectedYear'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json'
          },
        );
        if (riwayatAbsen.statusCode == 200) {
          final jsonData =
              jsonDecode(riwayatAbsen.body) as Map<String, dynamic>;
          if (jsonData.containsKey('data')) {
            final dataList = jsonData['data'] as List<dynamic>;

            setState(() {
              _rows = dataList.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['tanggal_absen'])),
                    DataCell(Text(data['jam_masuk'])),
                    DataCell(Text(data['jam_pulang'].toString())),
                    DataCell(Text(data['status_absen'])),
                    DataCell(Text(data['keterangan'].toString())),
                    DataCell(Text(data['file'].toString())),
                  ],
                );
              }).toList();
              _isLoading = false;
            });
          } else {
            throw Exception('Gagal mengambil data');
          }
        } else {
          throw Exception('Kesalahan HTTP: ${riwayatAbsen.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _cariData(String selectedMonth, String selectedYear) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
      var idUser = widget.idPegawai;
      http.Response riwayatAbsen = await http.get(
        Uri.parse(
          '$url/api/riwayat-absen/$idUser/$selectedMonthNumber/$selectedYear',
        ),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (riwayatAbsen.statusCode == 200) {
        final jsonData = jsonDecode(riwayatAbsen.body) as Map<String, dynamic>;
        if (jsonData.containsKey('data')) {
          final dataList = jsonData['data'] as List<dynamic>;
          setState(() {
            _rows = dataList.map((data) {
              return DataRow(
                cells: [
                  DataCell(Text(data['tanggal_absen'])),
                  DataCell(Text(data['jam_masuk'])),
                  DataCell(Text(data['jam_pulang'].toString())),
                  DataCell(Text(data['status_absen'])),
                  DataCell(Text(data['keterangan'].toString())),
                  DataCell(Text(data['file'].toString())),
                ],
              );
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Gagal mengambil data');
        }
      } else {
        throw Exception('Kesalahan HTTP: ${riwayatAbsen.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCard(int index) {
    final dataRow = _rows[index];
    final cells = dataRow.cells.toList();
    final tanggal = (cells[0].child as Text).data ??
        DateTime.now().toString().substring(0, 10);
    final jamMasuk = (cells[1].child as Text).data;
    final statusAbsen = (cells[3].child as Text).data;
    final keterangan = (cells[4].child as Text).data;
    final file = (cells[5].child as Text).data;
    final jamPulang = (cells[2].child as Text).data;
    String? jamPulangOk;
    if (jamPulang == 'Belum Pulang' &&
        tanggal != DateTime.now().toString().substring(0, 10)) {
      jamPulangOk = 'TAP';
    } else {
      jamPulangOk = (cells[2].child as Text).data;
    }
    IconData statusIcon;
    Color statusColor;
    Text status;
    switch (statusAbsen) {
      case '1':
        statusIcon = Icons.check;
        statusColor = const Color.fromARGB(255, 128, 249, 170);
        status = const Text('Hadir',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '2':
        statusIcon = Icons.car_repair;
        statusColor = const Color.fromARGB(255, 134, 255, 245);
        status = const Text('Dinas Luar',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '3':
        statusIcon = Icons.assignment;
        statusColor = const Color.fromARGB(255, 255, 243, 131);
        status = const Text('Izin',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '4':
        statusIcon = Icons.local_hospital;
        statusColor = const Color.fromARGB(255, 255, 72, 133);
        status = const Text('Sakit',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '6':
        statusIcon = Icons.close;
        statusColor = const Color.fromARGB(255, 229, 80, 255);
        status = const Text('Cuti',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '5':
        statusIcon = Icons.close;
        statusColor = const Color.fromARGB(255, 255, 170, 43);
        status = const Text('IDLK',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      default:
        statusIcon = Icons.error;
        statusColor = Colors.white;
        status = const Text('Tidak Diketahui',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
    }

    return Card(
      key: ValueKey<String>('card_$index'),
      margin: const EdgeInsets.all(8),
      color: const Color.fromARGB(255, 255, 255, 255),
      elevation: 4,
      shape: const RoundedRectangleBorder(),
      child: Stack(children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 3,
          child: Container(
            color: Colors.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tanggal,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        padding: const EdgeInsets.all(1),
                        child: CircleAvatar(
                          backgroundColor: statusColor,
                          radius: 8,
                          child: Icon(
                            statusIcon,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      status,
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (statusAbsen != "1")
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Keterangan:',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '$keterangan',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_circle_right_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jam Masuk: $jamMasuk',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (statusAbsen != "1")
                Row(
                  children: [
                    GestureDetector(
                        onTap: () {
                          String safeUrl = '$url/$file';
                          String encodedUrl = Uri.encodeComponent(safeUrl);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    LihatSpt(imageUrl: encodedUrl)),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 236, 181, 255),
                            border: Border.all(
                              color: const Color.fromARGB(255, 187, 0, 255),
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Color.fromARGB(255, 187, 0, 255),
                              ),
                              Text(
                                ' FOTO ',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 187, 0, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ))
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_circle_left_outlined,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jam Pulang: $jamPulangOk',
                      style: TextStyle(
                        color: jamPulang != 'TK' ? Colors.black : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Future<void> _refreshData() async {
    if (SyncLimiter.canSync()) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _fetchData();
        _isLoading = false;
      });
    } else {
      Alert.alertwarning(context, "Refresh maksimal 3 kali dalam 1 menit!");
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),

          title: const Center(
            child: Text(
              'Riwayat Absen',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
                  : ListView.builder(
                      itemCount:
                          1 + _rows.length,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Row(
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
                                    'Desember',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(width: 16),
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
                              ]);
                        } else {
                          return _buildCard(index - 1);
                        }
                      },
                    ),
            ),
          ),
        ));
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
