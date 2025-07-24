import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';

class Izin extends StatefulWidget {
  const Izin({super.key});

  @override
  State<Izin> createState() => _IzinState();
}

class _IzinState extends State<Izin> with TickerProviderStateMixin {
    bool _enabled = true;

  late final String url = SpUtil.getString("url") ?? '';
  var idUser = SpUtil.getString("id_user") ?? '';
  late Future<List<Map<String, dynamic>>> futureData;
  bool isLoading = false;
  late String selectedYear = DateTime.now().year.toString();
  late String selectedMonth = Bulan().getMonthName(DateTime.now().month);

  List<dynamic> _riwayatIzin = [];
  TabController? _controller;

  @override
  void initState() {
    super.initState();
              _enabled = false;

    if(mounted) {
      _controller?.addListener(() {
        setState(() {
          futureData = fetchData(selectedMonth, selectedYear);
        });
      });
      futureData = fetchData(selectedMonth, selectedYear);
      _refreshData();
    }
    
  }

  Future<List<Map<String, dynamic>>> fetchData(
      String month, String year) async {
        if (mounted) {
    setState(() {
      isLoading = true;
    });
        }
    String monthNumber = Bulan().getMonthNumber(month);
    final idUser = SpUtil.getString("id_user") ?? '';
    String? link;
    link = '$url/api/izin/riwayat-izin/$idUser/$monthNumber/$year';

    final response = await http.get(Uri.parse(link));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body)['data'];
      if (mounted) {
        setState(() {
        _riwayatIzin = responseData;
        _controller?.animateTo(0);
        isLoading = false;
      });
      }
      
      return responseData.cast<Map<String, dynamic>>();
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
          _riwayatIzin = []; // Reset data jika gagal
        });
      }
      throw Exception('Gagal memuat data izin');
    }
  }

  void searchByDate(String month, String year) {
    if (mounted) {
      setState(() {
        futureData = fetchData(month, year);
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    searchByDate(selectedMonth, selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Skeletonizer(
                      enabled: _enabled,
                      enableSwitchAnimation: true,
        child: Stack(
          children: [
            Header(),
            Column(
              children: [
                SizedBox(height: size.height * 0.15),
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
                    child: Column(
                      children: [
                        const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Riwayat Izin/Cuti/Sakit/Dinas Luar',
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
                                      if (mounted) {
                                        setState(() {
                                          selectedMonth = newValue!;
                                        });
                                      }
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
                                      if (mounted) {
                                        setState(() {
                                          selectedYear = newValue!;
                                        });
                                      }
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
                                    if (!isLoading) {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      await Future.delayed(const Duration(seconds: 2));
                                      searchByDate(selectedMonth, selectedYear);
                                    }
                                  },
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Cari',
                                          style: TextStyle(
                                            color: Colors.white,
                                          )),
                                ),
                              ]),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              itemCount: _riwayatIzin.length,
                              itemBuilder: (context, index) {
                                Text jenisStatus;
        
                                switch (_riwayatIzin[index]['jenis_approval'].toString()) {
                                  case '2':
                                    jenisStatus = const Text('Dinas Luar ',
                                        style: TextStyle(color: Colors.black));
                                    break;
                                  case '3':
                                    jenisStatus = const Text('Izin ',
                                        style: TextStyle(color: Colors.black));
                                    break;
                                  case '4':
                                    jenisStatus = const Text('Sakit ',
                                        style: TextStyle(color: Colors.black));
                                    break;
                                  case '5':
                                    jenisStatus = const Text('IDLK ',
                                        style: TextStyle(color: Colors.black));
                                    break;
                                  case '6':
                                    jenisStatus = const Text('Cuti ',
                                        style: TextStyle(color: Colors.black));
                                    break;
                                  default:
                                    jenisStatus = const Text('Belum Disetujui ',
                                        style: TextStyle(color: Colors.black));
                                }
        
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8,right: 8),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 1,
                                        color: const Color.fromARGB(255, 215, 215, 215), // Warna border biru
                                      ),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => navigateToDetailPage(
                                                              _riwayatIzin[index],
                                                              (_riwayatIzin[index]
                                                                  ['no_urut'])),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(DateFormat('EEEE, dd/MM/yyyy', 'id')
                                                                    .format(DateTime.parse(_riwayatIzin[index]['tgl_group']
                                                                .toString()))
                                                            ,
                                                            style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16),
                                                          ),
                                                          Row(
                                                            children: [
                                                              jenisStatus,
                                                              if (_riwayatIzin[index][
                                                                          'id_keterangan'] !=
                                                                      null &&
                                                                  _riwayatIzin[index]
                                                                          ['tgl_absen'] ==
                                                                      DateTime.now()
                                                                          .toString())
                                                                const Chip(
                                                                  padding:
                                                                      EdgeInsets.all(0),
                                                                  backgroundColor:
                                                                      Colors.red,
                                                                  label: Text(
                                                                      'Pulang Cepat',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white)),
                                                                ),
                                                            ],
                                                          ),
                                                          Text(
                                                            '${_riwayatIzin[index]['durasi']} Hari',
                                                            style: const TextStyle(
                                                                color: Colors.black),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      if (_riwayatIzin[index]
                                                                  ['status_approval'] ==
                                                              1 &&
                                                          DateTime.parse(_riwayatIzin[index]
                                                                  ['timestamp'])
                                                              .isAfter(DateTime.now()
                                                                  .subtract(const Duration(
                                                                      days: 1))))
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(4),
                                                            color: const Color.fromARGB(
                                                                255, 255, 168, 162),
                                                          ),
                                                          child: IconButton(
                                                            padding: EdgeInsets.zero,
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed: () => _confirmDelete(
                                                                _riwayatIzin[index]
                                                                    ['id_approval']),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -20),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFF0F4FD),
          onPressed: () async {
            // Navigasi ke halaman buat_izin dan tangkap data balikan
            final result = await Navigator.pushNamed(context, '/buat_izin');
            if (result == true) {
              if (mounted) {
                // Jika data berhasil ditambahkan, refresh data
                setState(() {
                  _controller?.animateTo(1); // Ubah ke tab riwayat pengajuan
                  searchByDate(selectedMonth, selectedYear); // Refresh data
                });
              }
              
            }
          },
          tooltip: 'Tambah Izin',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Fungsi untuk mengkonfirmasi penghapusan data
  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                // Panggil fungsi untuk menghapus data di sini
                _deleteItem(item);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus data
  Future<void> _deleteItem(id) async {
    final urlDel = '$url/api/izin/hapus-izin/$idUser/$id';
    try {
      final response = await http.get(Uri.parse(urlDel));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SpUtil.putBool('is_PulangCepat', false);
        String message = json.encode(data["message"]).replaceAll('"', '');
        // ignore: use_build_context_synchronously
        Alert.alertsuccess(context, message);
        setState(() {
          _refreshData();
        });
      } else {
        // ignore: use_build_context_synchronously
        Alert.alerterror(context, 'Gagal menghapus data, silahkan coba lagi!');
      }
    } catch (error) {
      // print('Error: $error');
    }
  }

  void navigateToDetailPage(Map<String, dynamic> data, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPengajuanIzin(data: data, noUrut: id),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2020 + 1, (index) {
      String year = (2020 + index).toString();
      return DropdownMenuItem<String>(
        value: year,
        child: Text(year),
      );
    });
  }
}
