import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mobileabsensi/widget/bulan.dart';
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
    fetchData(selectedMonth,selectedYear);
  }

  Future<void> fetchData(String selectedMonth,String selectedYear) async {
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

  void cariData(String selectedMonth,String selectedYear) {
    setState(() {
      isLoading = true;
    });
    fetchData(selectedMonth,selectedYear);
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
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Statistik',style: TextStyle(color: Colors.white),),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color:Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
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
    );
  }

  Widget _buildDropdownRow(List<String> monthNames) {
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
          items: monthNames.map<DropdownMenuItem<String>>((String value) {
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
          onPressed: () { if (!isLoading) {
                        cariData(selectedMonth, selectedYear);
                      }
          },
          child: const Text('Cari'),
        ),
      ],
    );
  }

  Widget _buildChartData() {
    final totalAbsen = data!['absen']['telat'] + data!['absen']['tepat'];
    final totalIzin = data!['izin']['dl'] + data!['izin']['izin'] + data!['izin']['sakit'] + data!['izin']['cuti'] + data!['izin']['idlk'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Pie chart for 'Absen'
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
                        color: Colors.red,
                        title: '${data!['absen']['telat']} (${(data!['absen']['telat'] / totalAbsen * 100).toStringAsFixed(1)}%) Telat',
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: data!['absen']['tepat'].toDouble(),
                        color: Colors.green,
                        title: '${data!['absen']['tepat']} (${(data!['absen']['tepat'] / totalAbsen * 100).toStringAsFixed(1)}%) Tepat',
                        radius: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Absen (Total: $totalAbsen)'),

          const SizedBox(height: 20),

          // Pie chart for 'Izin'
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
                        color: Colors.blue,
                        title: '${data!['izin']['dl']} (${(data!['izin']['dl'] / totalIzin * 100).toStringAsFixed(1)}%) Dinas Luar',
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: data!['izin']['izin'].toDouble(),
                        color: Colors.orange,
                        title: '${data!['izin']['izin']} (${(data!['izin']['izin'] / totalIzin * 100).toStringAsFixed(1)}%) Izin',
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: data!['izin']['sakit'].toDouble(),
                        color: Colors.purple,
                        title: '${data!['izin']['sakit']} (${(data!['izin']['sakit'] / totalIzin * 100).toStringAsFixed(1)}%) Sakit',
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: data!['izin']['cuti'].toDouble(),
                        color: Colors.yellow,
                        title: '${data!['izin']['cuti']} (${(data!['izin']['cuti'] / totalIzin * 100).toStringAsFixed(1)}%) Cuti',
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: data!['izin']['idlk'].toDouble(),
                        color: Colors.grey,
                        title: '${data!['izin']['idlk']} (${(data!['izin']['idlk'] / totalIzin * 100).toStringAsFixed(1)}%) IDLK',
                        radius: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Izin (Total: $totalIzin)'),

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
                        value: data!['laporan']['tot_laphar'].toDouble(),
                        color: Colors.blueGrey,
                        title: '${data!['laporan']['tot_laphar']} (${100.0}%)', // Total Laporan always 100%
                        radius: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Laporan (Total: ${data!['laporan']['tot_laphar']})'),
        ],
      ),
    );
  }
}
