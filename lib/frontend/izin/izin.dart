import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:sp_util/sp_util.dart';

class Izin extends StatefulWidget {
  const Izin({super.key});

  @override
  State<Izin> createState() => _IzinState();
}

class _IzinState extends State<Izin> with TickerProviderStateMixin {
  late final String url = SpUtil.getString("url") ?? '';
  var idUser = SpUtil.getString("id_user") ?? '';
  late Future<List<Map<String, dynamic>>> futureData;
  bool isLoading = false;
  late String selectedYear = DateTime.now().year.toString();
  late String selectedMonth = Bulan().getMonthName(DateTime.now().month);
  int selectedIndex = 0;

  List<dynamic> _riwayatIzin = [];
  List<dynamic> _riwayatPengajuan = [];
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: list.length, vsync: this);
    _controller?.addListener(() {
      setState(() {
        selectedIndex = _controller!.index;
        futureData = fetchData(selectedMonth, selectedYear);
      });
    });
    futureData = fetchData(selectedMonth, selectedYear);
    _refreshData();
  }

  Future<List<Map<String, dynamic>>> fetchData(
      String month, String year) async {
    setState(() {
      isLoading = true;
    });
    String monthNumber = Bulan().getMonthNumber(month);
    final idUser = SpUtil.getString("id_user") ?? '';
    String? link;
    if (selectedIndex == 0) {
      link = '$url/api/izin/riwayat-izin/pengajuan/$idUser/$monthNumber/$year';
    } else {
      link = '$url/api/izin/riwayat-izin/$idUser/$monthNumber/$year';
    }

    final response = await http.get(Uri.parse(link));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body)['data'];

      setState(() {
        if (selectedIndex == 0) {
          _riwayatIzin = responseData;
          selectedIndex = 0;
          _controller?.animateTo(0);
        } else {
          _riwayatPengajuan = responseData;
          selectedIndex = 1;
          _controller?.animateTo(1);
        }
        isLoading = false;
      });
      return responseData.cast<Map<String, dynamic>>();
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
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

  List<Widget> list = [
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.listCheck,
            color: Colors.yellow,
          ),
          SizedBox(width: 8),
          Text("Pengajuan Izin"),
        ],
      ),
    ),
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.envelope,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          Text("Riwayat Izin"),
        ],
      ),
    ),
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Center(
          child: Text(
            'Riwayat Izin',
            style: TextStyle(color: Colors.white),
          ),
        ),
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            color: const Color.fromARGB(163, 65, 65, 65),
            child: Column(
              children: [
                const SizedBox(
                    height: 10.0), // Memberikan jarak antara AppBar dan TabBar
                TabBar(
                  controller: _controller,
                  tabs: list,
                  indicatorColor: Colors.green,
                  dividerColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[500],
                  labelColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          buildTabContentWidget(
              _riwayatPengajuan, 'Tidak ada data Pengajuan Izin'),
          buildTabContentWidget(_riwayatIzin, 'Tidak ada data Riwayat Izin'),
          
        ],
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -20),
        child: FloatingActionButton(
          onPressed: () async {
            // Navigasi ke halaman buat_izin dan tangkap data balikan
            final result = await Navigator.pushNamed(context, '/buat_izin');
            if (result == true) {
              // Jika hasilnya sukses, ubah tab yang dipilih
              setState(() {
                _controller?.animateTo(1); // Ubah ke tab riwayat pengajuan
                searchByDate(selectedMonth, selectedYear); // Refresh data
              });
            }
          },
          tooltip: 'Tambah Izin',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget buildTabContentWidget(List<dynamic> data, String emptyMessage) {
    return Column(
      children: [
        Container(
          color: const Color.fromARGB(255, 240, 239, 239),
          child: Column(
            children: [
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
                      if (!isLoading) {
                        searchByDate(selectedMonth, selectedYear);
                      }
                    },
                    child: Text(isLoading ? '....' : 'Cari'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Failed to load data'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(emptyMessage));
              } else {
                return buildTabContent(snapshot.data!);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildTabContent(List<dynamic> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data found'));
    } else {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            Text jenisStatus;
            switch (selectedIndex) {
              case 2:
                break;
              default:
            }

            switch (data[index]['jenis_approval'].toString()) {
              case '2':
                jenisStatus = const Text('Status : Dinas Luar ',
                    style: TextStyle(color: Colors.black));
                break;
              case '3':
                jenisStatus = const Text('Status : Izin ',
                    style: TextStyle(color: Colors.black));
                break;
              case '4':
                jenisStatus = const Text('Status : Sakit ',
                    style: TextStyle(color: Colors.black));
                break;
              case '5':
                jenisStatus = const Text('Status : IDLK ',
                    style: TextStyle(color: Colors.black));
                break;
              case '6':
                jenisStatus = const Text('Status : Cuti ',
                    style: TextStyle(color: Colors.black));
                break;
              default:
                jenisStatus = const Text('Status : Belum Disetujui ',
                    style: TextStyle(color: Colors.black));
            }

            

            return Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 3, // Ketebalan border
                      child: Container(
                        color: Colors.blue, // Warna border biru
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data[index]['tgl_group'].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        'Lama Izin: ${data[index]['durasi']} Hari',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      Row(
                                        children: [
                                          jenisStatus,
                                          if (data[index]['id_keterangan'] != null && data[index]['tgl_absen'] == DateTime.now().toString())
                                          const Chip(
                                            padding: EdgeInsets.all(0),
                                            backgroundColor: Colors.red,
                                            label: Text('Pulang Cepat',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: const Color.fromARGB(
                                          255, 162, 190, 255),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.remove_red_eye,
                                          color:
                                              Color.fromARGB(255, 0, 26, 140)),
                                      onPressed: () => navigateToDetailPage(
                                          data[index], data[index]['no_urut']),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  if (data[index]['status_approval'] == 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: const Color.fromARGB(
                                            255, 255, 168, 162),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _confirmDelete(
                                            data[index]['id_approval']),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
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
