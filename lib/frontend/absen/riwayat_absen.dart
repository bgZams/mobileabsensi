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

class AbsensiModel {
  final String tanggalAbsen;
  final String jamMasuk;
  final String jamPulang;
  final String statusAbsen;
  final String keterangan;
  final String file;
  final String idAbsen;

  AbsensiModel({
    required this.tanggalAbsen,
    required this.jamMasuk,
    required this.jamPulang,
    required this.statusAbsen,
    required this.keterangan,
    required this.file,
    required this.idAbsen,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      tanggalAbsen: json['tanggal_absen']?.toString() ?? '-',
      jamMasuk: json['jam_masuk']?.toString() ?? '-',
      jamPulang: json['jam_pulang']?.toString() ?? 'Belum Pulang',
      statusAbsen: json['status_absen']?.toString() ?? '0',
      keterangan: json['keterangan']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      idAbsen: json['id_absen']?.toString() ?? '0',
    );
  }
}

class RiwayatAbsen extends StatefulWidget {
  const RiwayatAbsen({super.key});

  @override
  RiwayatAbsenState createState() => RiwayatAbsenState();
}

class RiwayatAbsenState extends State<RiwayatAbsen> {
  final String url = SpUtil.getString("url") ?? '';

  List<AbsensiModel> _dataList = [];
  bool _isLoading = true;
  String selectedYear = '';
  String selectedMonth = '';

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
    setState(() => _isLoading = true);

    if (SpUtil.getString("id_user") == null) return;

    try {
      String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
      var idUser = SpUtil.getString("id_user");

      final response = await http.get(
        Uri.parse('$url/api/riwayat-absen/$idUser/$selectedMonthNumber/$selectedYear'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonData.containsKey('data')) {
          final List<dynamic> rawList = jsonData['data'];

          if (mounted) {
            setState(() {
              _dataList = rawList.map((e) => AbsensiModel.fromJson(e)).toList();
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _dataList = [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          const Header(),
          Padding(
            padding: EdgeInsets.only(top: size.height * 0.15),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Riwayat Absen',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 50, 50, 50)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDropdown(selectedMonth, 'Pilih Bulan', (val) => setState(() => selectedMonth = val!), [
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
                                ]),
                                const SizedBox(width: 16),
                                _buildDropdown(selectedYear, 'Pilih Tahun', (val) => setState(() => selectedYear = val!), _getYearList()),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 67, 60, 130)),
                                  onPressed: _isLoading ? null : _fetchData,
                                  child: const Text('Cari', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _isLoading
                        ? SliverToBoxAdapter(
                            child: Skeletonizer(
                              enabled: true,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 5,
                                itemBuilder: (context, index) => const Card(child: SizedBox(height: 80)),
                              ),
                            ),
                          )
                        : (_dataList.isEmpty)
                            ? const SliverToBoxAdapter(
                                child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text("Tidak ada data absen"))),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return AbsensiCardItem(
                                      data: _dataList[index],
                                      url: url,
                                      onDetailPressed: (id) => detailDataAbsen(id),
                                    );
                                  },
                                  childCount: _dataList.length,
                                ),
                              ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, String hint, Function(String?) onChanged, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF0F4FD), borderRadius: BorderRadius.circular(5)),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }

  List<String> _getYearList() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) => (2018 + index).toString());
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


          final tanggalAbsen = data['tgl_absen']?.toString() ?? 'N/A';
          final hari = data['hari']?.toString() ?? 'N/A';

          String jamMasuk = 'N/A';
          if (data['timestamp_masuk'] != null) {
            try {
              DateTime parsedTime = DateTime.parse(data['timestamp_masuk']);
              jamMasuk = DateFormat('HH:mm').format(parsedTime);
            } catch (e) {
              // print('Error parsing timestamp_masuk: $e');
            }
          }

          String jamPulang = 'Belum Pulang';
          if (data['timestamp_pulang'] != null) {
            try {
              DateTime parsedTime = DateTime.parse(data['timestamp_pulang']);
              jamPulang = DateFormat('HH:mm').format(parsedTime);
            } catch (e) {
              // print('Error parsing timestamp_pulang: $e');
            }
          }

          final ssidMasuk = data['SSID']?.toString() ?? 'Tidak ada data';
          final ssidPulang = data['SSID_pulang']?.toString() ?? 'Tidak ada data';
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
          SnackBar(content: Text('Gagal mengambil data absen.')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat terhubung ke server.')),
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
 
}

class AbsensiCardItem extends StatelessWidget {
  final AbsensiModel data;
  final String url;
  final Function(String) onDetailPressed;

  const AbsensiCardItem({super.key, required this.data, required this.url, required this.onDetailPressed});

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (data.statusAbsen) {
      case '1':
        statusIcon = FontAwesomeIcons.handPointer;
        statusColor = const Color.fromARGB(255, 128, 249, 170);
        statusText = 'Hadir';
        break;
      case '2':
        statusIcon = Icons.car_repair;
        statusColor = const Color.fromARGB(255, 134, 255, 245);
        statusText = 'Dinas Luar';
        break;
      case '3':
        statusIcon = Icons.assignment;
        statusColor = const Color.fromARGB(255, 255, 243, 131);
        statusText = 'Izin';
        break;
      case '4':
        statusIcon = Icons.local_hospital;
        statusColor = const Color.fromARGB(255, 255, 72, 133);
        statusText = 'Sakit';
        break;
      case '6':
        statusIcon = Icons.copyright;
        statusColor = const Color.fromARGB(255, 229, 80, 255);
        statusText = 'Cuti';
        break;
      case '5':
        statusIcon = Icons.car_repair;
        statusColor = const Color.fromARGB(255, 255, 170, 43);
        statusText = 'IDLK';
        break;
      default:
        statusIcon = Icons.error;
        statusColor = Colors.white;
        statusText = 'N/A';
    }

    String jamPulangDisplay = data.jamPulang;
    bool isToday = data.tanggalAbsen == DateTime.now().toString().substring(0, 10);

    if (data.jamPulang == 'Belum Pulang' && !isToday && SpUtil.getString('id_type') != '1') {
      jamPulangDisplay = 'TAP';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(data.tanggalAbsen),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (data.statusAbsen == '1') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimeBadge(Icons.login, data.jamMasuk, const Color.fromRGBO(67, 60, 130, 1)),
                      const SizedBox(width: 12),
                      _buildTimeBadge(Icons.logout, jamPulangDisplay, jamPulangDisplay == 'TAP' ? Colors.red : const Color.fromRGBO(201, 131, 222, 1)),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      String safeUrl = '$url/${data.file}';
                      String encodedUrl = Uri.encodeComponent(safeUrl);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LihatSpt(imageUrl: encodedUrl, keterangan: data.keterangan)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 236, 181, 255),
                        border: Border.all(color: const Color.fromARGB(255, 187, 0, 255)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 14, color: Color.fromARGB(255, 187, 0, 255)),
                          SizedBox(width: 4),
                          Text('FOTO', style: TextStyle(color: Color.fromARGB(255, 187, 0, 255), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (data.statusAbsen == '1') {
                onDetailPressed(data.idAbsen);
              }
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Icon(statusIcon, size: 20, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(statusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeBadge(IconData icon, String time, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(color: color == Colors.red ? Colors.red : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('EEEE, dd/MM/yyyy', 'id').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }
}
