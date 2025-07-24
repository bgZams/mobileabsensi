import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/absen/lihat_spt.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';

class RiwayatAbsen extends StatefulWidget {
  const RiwayatAbsen({super.key});

  @override
  RiwayatAbsenState createState() => RiwayatAbsenState();
}

class RiwayatAbsenState extends State<RiwayatAbsen> {
  bool _enabled = true;

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
              _enabled = false;

    DateTime now = DateTime.now();
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

  Future<void> _fetchData() async {
    if (SpUtil.getString("id_user") != null && mounted) {
      try {
        String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
        var idUser = SpUtil.getString("id_user");
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
                      DataCell(Text(data['id_absen'].toString())),
                    ],
                  );
              }).whereType<DataRow>().toList();
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
      var idUser = SpUtil.getString("id_user");
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
                  DataCell(Text(data['id_absen'].toString())),
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


Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.black87, fontSize: 14),
        children: <TextSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

// Method baru untuk membuat tabel terpisah
Widget _buildAttendanceTable(String title, List<Map<String, String>> data) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      children: [
        // Header tabel
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Data tabel
        Container(
          color: Colors.purple.shade50,
          child: Column(
            children: data.map((item) => _buildTableRow(item['label']!, item['value']!)).toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTableRow(String label, String value) {
  return Container(
    color: Colors.purple.shade50,
    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          ': ',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

void detailDataAbsen(idAbsen) async {
  try {
    final response = await http.get(
      Uri.parse('$url/api/absen/riwayat-absen-detail/$idAbsen'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (mounted) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);

        if (responseJson['data'] != null) {
          final Map<String, dynamic> data = responseJson['data'] as Map<String, dynamic>;

          // final idAbsenStr = data['id_absen']?.toString() ?? 'N/A';
          final tanggalAbsen = data['tgl_absen']?.toString() ?? 'N/A';
          // final username = data['username']?.toString() ?? 'N/A';
          // final namaLengkap = data['nama_lengkap']?.toString() ?? 'N/A';
          final hari = data['hari']?.toString() ?? 'N/A';

          String jamMasuk = 'N/A';
          if (data['timestamp_masuk'] != null) {
            try {
              DateTime parsedTime = DateTime.parse(data['timestamp_masuk']);
              jamMasuk = DateFormat('HH:mm').format(parsedTime);
            } catch (e) {
              print('Error parsing timestamp_masuk: $e');
            }
          }

          String jamPulang = 'Belum Pulang';
          if (data['timestamp_pulang'] != null) {
            try {
              DateTime parsedTime = DateTime.parse(data['timestamp_pulang']);
              jamPulang = DateFormat('HH:mm').format(parsedTime);
            } catch (e) {
              print('Error parsing timestamp_pulang: $e');
            }
          }

          final ssidMasuk = data['SSID']?.toString() ?? 'Tidak ada data';
          final ssidPulang = data['SSID_pulang']?.toString() ?? 'Tidak ada data';
          // final statusAbsen = data['status']?.toString() ?? 'N/A';
          // final keterangan = data['keterangan']?.toString() ?? '-';
          // final file = data['file']?.toString() ?? 'Tidak ada';
          
          // Data baru dari perhitungan
          final jamMasukStandar = data['jam_masuk_standar']?.toString() ?? 'N/A';
          final jamPulangStandar = data['jam_pulang_standar']?.toString() ?? 'N/A';
          final totalJamKerja = data['total_jam_kerja']?.toString() ?? '0';
          final totalTerlambat = data['total_terlambat']?.toString() ?? '0';
          final totalPulangCepat = data['total_pulang_cepat']?.toString() ?? '0';

          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Detail Absen'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Tanggal Absen', '$tanggalAbsen ($hari)'),
                      
                      // Tabel Data Masuk
                      _buildAttendanceTable('DATA MASUK', [
                        {'label': 'Jam Masuk', 'value': jamMasuk},
                        {'label': 'SSID Masuk', 'value': ssidMasuk},
                      ]),
                      
                      // Tabel Data Pulang
                      _buildAttendanceTable('DATA PULANG', [
                        {'label': 'Jam Pulang', 'value': jamPulang},
                        {'label': 'SSID Pulang', 'value': ssidPulang},
                      ]),
                      
                      // Tabel Perhitungan
                      _buildCalculationTable('PERHITUNGAN', [
                        {'label': 'Total Jam Kerja', 'value': totalJamKerja},
                        {'label': 'Total Terlambat', 'value': totalTerlambat},
                        {'label': 'Total Pulang Cepat', 'value': totalPulangCepat},
                      ]),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
                    child: const Text('Tutup'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada detail data absen untuk Absen ini.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data absen. Status: ${response.statusCode}')),
        );
      }
    }
  } catch (e) {
    print('Error fetching detail absen: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan atau server.')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Method tambahan untuk tabel perhitungan dengan warna berbeda
Widget _buildCalculationTable(String title, List<Map<String, String>> data) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      children: [
        // Header tabel
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade400, // Warna berbeda untuk perhitungan
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Data tabel
        Container(
          color: Colors.blue.shade50,
          child: Column(
            children: data.map((item) => _buildCalculationRow(item['label']!, item['value']!)).toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCalculationRow(String label, String value) {
  return Container(
    color: Colors.blue.shade50,
    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          ': ',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCard(int index) {
    final dataRow = _rows[index];
    final cells = dataRow.cells.toList();
    final tanggal = (cells[0].child as Text).data ??
        DateTime.now().toString().substring(0, 10);
    final jamMasuk = (cells[1].child as Text).data;
    final jamPulang = (cells[2].child as Text).data;
    final statusAbsen = (cells[3].child as Text).data;
    final keterangan = (cells[4].child as Text).data;
    final file = (cells[5].child as Text).data;
    final idAbsen = (cells[6].child as Text).data;
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
        statusIcon = FontAwesomeIcons.handPointer;
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
        statusIcon = Icons.copyright;
        statusColor = const Color.fromARGB(255, 229, 80, 255);
        status = const Text('Cuti',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ));
        break;
      case '5':
        statusIcon = Icons.car_repair;
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

    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white, // Beri warna latar belakang pada Container
                      borderRadius: BorderRadius.circular(8), // Tambahkan sedikit border radius jika diinginkan
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Warna shadow dengan opasitas
                          spreadRadius: 2, // Seberapa jauh shadow menyebar
                          blurRadius: 5, // Tingkat keburaman shadow
                          offset: Offset(0, 3), // Posisi shadow (x, y)
                        ),
                      ],
                    ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy', 'id')
                        .format(DateTime.parse(tanggal)),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (statusAbsen != "1")
                    Column(
                      children: [
                        SizedBox(height: 10,),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                String safeUrl = '$url/public/$file';
                                String encodedUrl = Uri.encodeComponent(safeUrl);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LihatSpt(imageUrl: encodedUrl,
                                              keterangan: keterangan!)),
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
                                        fontSize: 12
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    )
                  else
                    SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_circle_right_outlined,
                                  color: Color.fromRGBO(67, 60, 130, 1),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  jamMasuk ?? '',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_circle_left_outlined,
                                color: Color.fromRGBO(201, 131, 222, 1),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                jamPulangOk!,
                                style: TextStyle(
                                  color:
                                      jamPulang != 'TK' ? Colors.black : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              Spacer(),
              GestureDetector(
                      onTap: () {
                        if(statusAbsen != '1' && statusAbsen != '5') {
                          String safeUrl = '$url/public/$file';
                          String encodedUrl = Uri.encodeComponent(safeUrl);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    LihatSpt(imageUrl: encodedUrl,
                                        keterangan: keterangan!)),
                          );
                        } else {
                          String idAbsen = (cells[6].child as Text).data ?? '';
                          if (idAbsen.isNotEmpty) {
                            detailDataAbsen(idAbsen);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ID Absen tidak ditemukan')),
                            );
                          }
                        }
                      },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        padding: const EdgeInsets.all(1),
                        child: CircleAvatar(
                          backgroundColor: statusColor,
                          radius: 8,
                          child: Column(
                            children: [
                              Icon(
                                statusIcon,
                                color: Colors.black,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      status,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), 
      
    ]);
  }

  

  Future<void> _refreshData() async {
    // if (SyncLimiter.canSync()) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _fetchData();
        _isLoading = false;
      });
    // } else {
    //   Alert.alertwarning(context, "Refresh maksimal 3 kali dalam 1 menit!");
    // }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Header(),
          // Scrollable content area taking most of the screen
          Column(
            children: [
              // Spacer to push content down to create overlap
              SizedBox(height: size.height * 0.15),
      
              // Content area
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Skeletonizer(
                      enabled: _enabled,
                      enableSwitchAnimation: true,
                      effect:  ShimmerEffect(duration: Duration (seconds: 10 ),),
                      ignoreContainers: true,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Riwayat Absen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 50, 50, 50),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF0F4FD),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5)),
                                  ),
                                  child: DropdownButton<String>(
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
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF0F4FD),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5)),
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedYear,
                                    hint: const Text('Pilih Tahun'),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedYear = newValue!;
                                      });
                                    },
                                    items: _getYearItems(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 67, 60, 130),
                                  ),
                                  onPressed: () async {
                                    if (!_isLoading) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await Future.delayed(const Duration(seconds: 2));
                                    _cariData(selectedMonth, selectedYear);
                                    }
                                  },
                                  child: const Text('Cari',
                                      style: TextStyle(
                                        color: Colors.white,
                                      )),
                                ),
                              ]),
                          RefreshIndicator(
                            onRefresh: _refreshData,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _rows.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, right: 8),
                                        child: _buildCard(index),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
