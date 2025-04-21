import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mobileabsensi/widget/bulan.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:sp_util/sp_util.dart';

class Statistik extends StatefulWidget {
  const Statistik({super.key});

  @override
  StatistikState createState() => StatistikState();
}

class StatistikState extends State<Statistik> {
  var url = SpUtil.getString("url") ?? '';
  var idUser = SpUtil.getString("id_user") ?? '';
  late String selectedMonth;
  late String selectedYear;
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = _getMonthName(now.month);
    selectedYear = now.year.toString();
    fetchData(selectedMonth, selectedYear);
  }

  Future<void> fetchData(String selectedMonth, String selectedYear) async {
    String monthNumber = Bulan().getMonthNumber(selectedMonth);
    var urlto = '$url/api/statistik/$idUser/$monthNumber/$selectedYear';
    try {
      final response = await http.get(Uri.parse(urlto));
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void cariData(String selectedMonth, String selectedYear) {
    setState(() {
      isLoading = true;
    });
    fetchData(selectedMonth, selectedYear);
  }

  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) {
      final year = 2018 + index;
      return DropdownMenuItem<String>(
        value: year.toString(),
        child: Text(year.toString()),
      );
    });
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

  @override
  Widget build(BuildContext context) {
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
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background header that extends beyond what's visible
          Header(),

          // Scrollable content area taking most of the screen
          Column(
            children: [
              // Spacer to push content down to create overlap
              SizedBox(height: size.height * 0.15),

              // Content area
              Expanded(
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
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 5),
                      _buildDropdownRow(monthNames),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : data == null
                              ? const Text('No data available')
                              : _buildChartData(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(List<String> monthNames) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Color(0xFFF0F4FD),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
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
          ].map<DropdownMenuItem<String>>((String value) {
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
          borderRadius: const BorderRadius.all(Radius.circular(5)),
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
          backgroundColor: const Color.fromARGB(255, 67, 60, 130),
        ),
        onPressed: () {
          if (!isLoading) {
            cariData(selectedMonth, selectedYear);
          }
        },
        child: const Text('Cari',
            style: TextStyle(
              color: Colors.white,
            )),
      ),
    ]);
  }

  Widget _buildChartData() {
    final totalAbsen = data!['absen']['telat'] + data!['absen']['tepat'];
    final totalIzin = data!['izin']['dl'] +
        data!['izin']['izin'] +
        data!['izin']['sakit'] +
        data!['izin']['cuti'] +
        data!['izin']['idlk'];
    final double totalSemua = data!['izin']['dl'].toDouble() +
        data!['izin']['izin'].toDouble() +
        data!['izin']['sakit'].toDouble() +
        data!['izin']['cuti'].toDouble() +
        data!['izin']['idlk'].toDouble() +
        data!['absen']['tepat'].toDouble() +
        data!['absen']['telat'].toDouble();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Pie chart for 'Absen'
          const SizedBox(height: 20),
          Text('Hadir (Total: $totalAbsen)'),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: data!['absen']['telat'].toDouble(),
                        color: Color(0xFFC983DE),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['absen']['telat'] / totalAbsen * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Telat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value: data!['absen']['tepat'].toDouble(),
                        color: Color(0xFF433C82),
                        title:
                            '', // Set title to an empty string to avoid displaying 1.0
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['absen']['tepat'] / totalAbsen * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Tepat\nWaktu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text('Kehadiran (Total: ${totalIzin + totalAbsen})'),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: data!['izin']['dl'].toDouble(),
                        color: Color(0xFF433C82),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['izin']['dl'] / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Dinas\nLuar',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value: data!['izin']['izin'].toDouble(),
                        color: Color(0xFFF0F4FD),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['izin']['izin'] / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Izin',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value: data!['izin']['sakit'].toDouble(),
                        color: Color(0xFFC983DE),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['izin']['sakit'] / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Sakit',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value: data!['izin']['cuti'].toDouble(),
                        color: Color(0xFF433C82),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['izin']['cuti'] / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Cuti',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value: data!['izin']['idlk'].toDouble(),
                        color: Color(0xFFF0F4FD),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['izin']['idlk'] / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'IDLK',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value:
                            (data!['absen']['tepat'] + data!['absen']['telat'])
                                .toDouble(),
                        color: Color(0xFFC983DE),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${((data!['absen']['tepat'] + data!['absen']['telat']) / totalSemua * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Hadir',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
              'Laporan harian (Total: ${(data?['laporan']?['laphar_diisi']?.toInt() ?? 0) + (data?['laporan']?['laphar_tidak_diisi']?.toInt() ?? 0)})'),
          const SizedBox(height: 20),

          // Pie chart for 'Laporan'
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: data!['laporan']['laphar_diisi'].toDouble(),
                        color: Color(0xFF433C82),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['laporan']['laphar_diisi'] / ((data?['laporan']?['laphar_diisi']?.toInt() ?? 0) + (data?['laporan']?['laphar_tidak_diisi']?.toInt() ?? 0)) * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Laporan Diisi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PieChartSectionData(
                        value:
                            data!['laporan']['laphar_tidak_diisi'].toDouble(),
                        color: Color(0xFFC983DE),
                        title: '',
                        radius: 100,
                        badgeWidget: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${(data!['laporan']['laphar_tidak_diisi'] / ((data?['laporan']?['laphar_diisi']?.toInt() ?? 0) + (data?['laporan']?['laphar_tidak_diisi']?.toInt() ?? 0)) * 100).toStringAsFixed(0)}%\n',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'Laporan Tidak Diisi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
