import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/buat_apel.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
import 'package:sp_util/sp_util.dart';

class Apel extends StatefulWidget {
  const Apel({Key? key}) : super(key: key);

  @override
  State<Apel> createState() => _ApelState();
}

class _ApelState extends State<Apel> {
  var url = SpUtil.getString("url");
  late Future<List<Map<String, dynamic>>> _futureData;
  bool _isLoading = false;
  late String selectedYear = '';
  late String selectedMonth = '';

  get path => null;

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
          '$url/api/riwayat-epel/$idUser/$selectedMonthNumber/$selectedYear'));
      print(json.decode(response.body)['data']);
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
      throw Exception('Gagal memuat data, pastikan koneksi stabil');
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

  var random = Random();

  Future<void> _saveImage(BuildContext context, String foto) async {
    String? message;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Download image
      final http.Response response =
          await http.get(Uri.parse('$url/api/download-foto-apel/$foto'));

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      // print('$url/api/download-foto-apel/$foto');
      // Create an image name
      var filename = '${dir.path}/$foto';

      // Save to filesystem
      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      // Ask the user to save it
      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to disk';
      }
    } catch (e) {
      message = 'An error occurred while saving the image';
    }

    if (message != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text(' :: Riwayat Apel'),
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
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //tambah data
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BuatApel()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 0, 110, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('+ Apel',
                              style: TextStyle(color: Colors.white)),
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
                              return const Center(
                                  child: Text('Error: Data tidak ditemukan!'));
                            } else {
                              return SingleChildScrollView(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Card(
                                        color: const Color.fromARGB(
                                            255, 253, 247, 247),
                                        child: DataTable(
                                          columns: const <DataColumn>[
                                            DataColumn(label: Text('Foto')),
                                            DataColumn(label: Text('Tanggal')),
                                            DataColumn(label: Text('Waktu')),
                                          ],
                                          rows: snapshot.data!.map((data) {
                                            return DataRow(cells: [
                                              DataCell(GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Column(
                                                          children: [
                                                            Text(
                                                              data['tanggal']
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                            ),
                                                            IconButton(
                                                              // Call the method we just created
                                                              onPressed:
                                                                  () async {
                                                                String foto =
                                                                    '${data['foto']}';
                                                                print(foto);

                                                                _saveImage(
                                                                    context,
                                                                    foto);
                                                              },
                                                              icon: const Icon(
                                                                  Icons.save),
                                                            ),
                                                          ],
                                                        ),
                                                        content: SizedBox(
                                                            width: 50,
                                                            child: Image.network(
                                                                '$url/${data['file'] ?? '$url/apel/broken.png'}')),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                'Tutup'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: SizedBox(
                                                  width: 50,
                                                  child: Image.network(
                                                      '$url/${data['file'] ?? '$url/apel/broken.png'}'),
                                                ),
                                              )),
                                              DataCell(Text(
                                                  data['tanggal'].toString())),
                                              DataCell(Text(data['created_at']
                                                  .toString())),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
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
