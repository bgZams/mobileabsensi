import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:sp_util/sp_util.dart';

class RiwayatPengajuanIzin extends StatefulWidget {
  const RiwayatPengajuanIzin({Key? key}) : super(key: key);

  @override
  State<RiwayatPengajuanIzin> createState() => _RiwayatPengajuanIzinState();
}

class _RiwayatPengajuanIzinState extends State<RiwayatPengajuanIzin> {
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
    selectedMonth = Bulan().getMonthName(now.month);
    _futureData = fetchData(selectedMonth, selectedYear);
  }




  Future<List<Map<String, dynamic>>> fetchData(String selectedMonth, String selectedYear) async {
  try {
    String selectedMonthNumber = Bulan().getMonthNumber(selectedMonth);
    final idUser = SpUtil.getString("id_user");
    final response = await http.get(Uri.parse('$url/api/riwayat-izin/pengajuan/$idUser/$selectedMonthNumber/$selectedYear'));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body)['data'];
      _isLoading = false;
      return responseData.cast<Map<String, dynamic>>();
    } else {
      _isLoading = false;
      throw const Text('Data tidak ditemukan');
    }
  } catch (e) {
    _isLoading = false;
    throw const Text('Data tidak ditemukan');
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
    double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Riwayat Pengajuan Izin',style: TextStyle(color: Colors.white),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                    child: Image.asset('assets/images/nodata.png'));
                              } else {
                                return SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Card(
                                        color: const Color.fromARGB(
                                            255, 253, 247, 247),
                                        child: SizedBox(
                                    width: deviceWidth * 1.2,

                                          child: DataTable(
                                            showCheckboxColumn: false,
                                            columns: const <DataColumn>[
                                              DataColumn(label: Text('Tanggal')),
                                              DataColumn(label: Text('Status')),
                                              DataColumn(label: Text('Durasi')),
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
                                                      const Text('RiwayatPengajuanIzin');
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
                                                    DataCell(Center(
                                                      child: Text('${data['durasi']
                                                          .toString()} Hari'),
                                                    ) ),
                                                  ],
                                                              // Di dalam builder DataTable, gunakan fungsi navigateToDetailPage
                                                  onSelectChanged: (selected) {
                                                    if (selected != null &&
                                                        selected) {
                                                      navigateToDetailPage(
                                                          data,
                                                          data[
                                                              'no_urut']);
                                                    }
                                                  });
                                            }).toList(),
                                          ),
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
