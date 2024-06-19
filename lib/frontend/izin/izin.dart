import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/widget/bulan.dart';
import 'package:sp_util/sp_util.dart';

class Izin extends StatefulWidget {
  const Izin({Key? key}) : super(key: key);

  @override
  State<Izin> createState() => _IzinState();
}

class _IzinState extends State<Izin> with TickerProviderStateMixin {
  late final String url = SpUtil.getString("url") ?? '';
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
    _controller = TabController(length: list().length, vsync: this);
    _controller?.addListener(() {
      setState(() {
        selectedIndex = _controller!.index;
        futureData = fetchData(selectedMonth, selectedYear);
        print(selectedIndex);
      });
    });
    futureData = fetchData(selectedMonth, selectedYear);
    _refreshData();
  }

  Future<List<Map<String, dynamic>>> fetchData(String month, String year) async {
    setState(() {
      isLoading = true;
    });
    String monthNumber = Bulan().getMonthNumber(month);
    final idUser = SpUtil.getString("id_user") ?? '';
    String link;
    if (selectedIndex == 0) {
      link = '$url/api/riwayat-izin/$idUser/$monthNumber/$year';
    } else {
      link = '$url/api/riwayat-izin/pengajuan/$idUser/$monthNumber/$year';
    }

    final response = await http.get(Uri.parse(link));
    print(response.body);

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
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
      throw Exception('Failed to load data');

    }
  }

  void searchByDate(String month, String year) {
    if(mounted){
      setState(() {
        futureData = fetchData(month, year);
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    searchByDate(selectedMonth, selectedYear);
  }

  List<Widget> list() {
    return [
      const Tab(
        icon: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.envelope, color: Colors.blue),
            SizedBox(width: 8),
            Text("Riwayat Izin"),
          ],
        ),
      ),
      const Tab(
        icon: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.listCheck, color: Colors.yellow),
            SizedBox(width: 8),
            Text("Pengajuan Izin"),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Center(
          child: Text(
            'Riwayat Izin',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            textAlign: TextAlign.center,
          ),
        ),
        bottom: TabBar(
          controller: _controller,
          tabs: list(),
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          buildTabContentWidget(_riwayatIzin, 'No data found for Riwayat Izin'),
          buildTabContentWidget(_riwayatPengajuan, 'No data found for Pengajuan Izin'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/buat_izin'),
        tooltip: 'Tambah Izin',
        child: const Icon(Icons.add),
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
            Color iconColor;
            Icon iconData;
            switch (selectedIndex) {
              case 2:
                iconColor = const Color.fromARGB(255, 175, 255, 179);
                iconData = const Icon(Icons.check, size: 25);
                break;
              default:
                iconColor = const Color.fromARGB(255, 231, 255, 122);
                iconData = const Icon(Icons.check, size: 25);
            }

            switch (data[index]['jenis_approval'].toString()) {
              case '2':
                jenisStatus = const Text('Status : Dinas Luar', style: TextStyle(color: Colors.black));
                break;
              case '3':
                jenisStatus = const Text('Status : Izin', style: TextStyle(color: Colors.black));
                break;
              case '4':
                jenisStatus = const Text('Status : Sakit', style: TextStyle(color: Colors.black));
                break;
              case '5':
                jenisStatus = const Text('Status : IDLK', style: TextStyle(color: Colors.black));
                break;
              case '6':
                jenisStatus = const Text('Status : Cuti', style: TextStyle(color: Colors.black));
                break;
              default:
                jenisStatus = const Text('Status : Belum Disetujui', style: TextStyle(color: Colors.black));
            }

            return Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
              child: Container(
                color: iconColor,
                child: Container(
                  color: const Color.fromARGB(255, 230, 240, 255),
                  child: ListTile(
                    title: Text(
                      data[index]['tgl_group'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Lama Izin: ${data[index]['durasi']} Hari', style: const TextStyle(color: Colors.black)),
                            jenisStatus,
                          ],
                        ),
                      ],
                    ),
                    onTap: () => navigateToDetailPage(data[index], data[index]['no_urut']),
                  ),
                ),
              ),
            );
          },
        ),
      );
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
