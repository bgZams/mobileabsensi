import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class LaporanHarian extends StatefulWidget {
  const LaporanHarian({Key? key}) : super(key: key);

  @override
  State<LaporanHarian> createState() => _LaporanHarianState();
}

class _LaporanHarianState extends State<LaporanHarian>
  with TickerProviderStateMixin {
  List<dynamic> _riwayatLaporan = [];
  List<dynamic> _riwayatPengajuan = [];
  String? url = SpUtil.getString("url");
  String? idUser;
  TabController? _controller;
  int selectedIndex = 0;
  late String selectedYear;
  late String selectedMonth;
  bool isLoading = true;
  bool value = false;
  List<DataRow> _rows = [];
  bool isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;

  void dataChange(){
    setState(() {
      value = true;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    _controller = TabController(length: list.length, vsync: this);
    _controller?.addListener(() {
      setState(() {
        selectedIndex = _controller!.index;
      });
    _fetchData();
    });
    _refreshData();
    initializePreferences();
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[month - 1];
  }

  String _getMonthNumber(String monthName) {
    const monthNumbers = {
      'Januari': '01', 'Februari': '02', 'Maret': '03', 'April': '04',
      'Mei': '05', 'Juni': '06', 'Juli': '07', 'Agustus': '08',
      'September': '09', 'Oktober': '10', 'November': '11', 'Desember': '12'
    };
    return monthNumbers[monthName] ?? '01';
  }


  List<Widget> list = [
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.envelope,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          Text("Riwayat LHK"),
        ],
      ),
    ),
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.listCheck,
            color: Colors.yellow,
          ),
          SizedBox(width: 8),
          Text("Pengajuan LHK"),
        ],
      ),
    ),
  ];

  Future<void> initializePreferences() async {
    await SpUtil.getInstance();
    setState(() {
      url = SpUtil.getString("url");
      idUser = SpUtil.getString("id_user");
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
  final idUser = SpUtil.getString("id_user");
  String selectedMonthNumber = _getMonthNumber(selectedMonth);
  try {
    String subUrl ='';
    if(selectedIndex == 0){
      subUrl = '$url/api/riwayat-lhk/$idUser/$selectedMonthNumber/$selectedYear';
    } else {
      subUrl = '$url/api/riwayat-lhk/pengajuan/$idUser';
    }
    final response = await http.get(
      Uri.parse(subUrl),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      setState(() {
        if (selectedIndex == 0) {
          _riwayatLaporan = jsonData['data'];
        } else {
          _riwayatPengajuan = jsonData['data'];
        }
      });

      if (jsonData.containsKey('data')) {
        final dataList = jsonData['data'] as List<dynamic>;

        setState(() {
          _rows = dataList.map((data) => DataRow(cells: [
            DataCell(Text(data['id'].toString() ?? 'N/A')),
            DataCell(Text(data['tgl'] ?? 'N/A')),
            DataCell(Text(data['jammulai'] ?? 'N/A')),
            DataCell(Text(data['jamselesai'] ?? 'N/A')),
            DataCell(Text(data['rincian_kegiatan'] ?? 'N/A')),
            DataCell(Text(data['status'] ?? 'N/A')),
          ])).toList();
          isLoading = false;
        });

      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load data');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    print("Error fetching data: $e");
  }
}

Future<void> _deleteLaporan(id) async {
  final urlDel = '$url/api/delete-lhk/$id}';

  try {
    final response = await http.delete(Uri.parse(urlDel));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String message = json.encode(data["message"]).replaceAll('"', '');
      // ignore: use_build_context_synchronously
      Alert.alertsuccess(context, message);
      setState(() {
        _refreshData();
      });
    } else {
      throw Exception('Failed to delete report');
    }
  } catch (error) {
    print('Error: $error');
  }
}



Future<void> _refreshData() async {
  await Future.delayed(const Duration(seconds: 2));
  if (mounted) {
    setState(() {
      _fetchData(); // Memanggil _fetchData untuk mendapatkan data terbaru
    });
  }
}

void navigateToEditLaporan(Map<String, dynamic> data) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditLaporan(
        data: data,           // Argument `data` yang benar
        onUpdate: _refreshData, // Callback `onUpdate` yang benar
      ),
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text('Laporan Harian',style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
        )),
        elevation: 4,
        flexibleSpace: const Image(
          image: AssetImage('assets/images/bannernav.png'),
          fit: BoxFit.cover,
        ),
        bottom: TabBar(
          controller: _controller,
          tabs: list,
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          _riwayatLaporan.isEmpty
              ? const Center(child: Text('No data found'))
              : Column(
                children: [
                  Column(
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
                                // Tombol Cari
                                ElevatedButton(
                                  onPressed: () {
                                    // _searchData(selectedMonth, selectedYear);
                                  },
                                  child: const Text('Cari'),
                                ),
                              ],
                            ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(onRefresh: () { return _refreshData(); },
                    child: SingleChildScrollView (child: _buildCards())),
                  ),
                ],
              ),
          _riwayatPengajuan.isEmpty
              ? const Center(child: Text('No data found'))
              : Column(
                children: [
                  Column(
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
                                // Tombol Cari
                                ElevatedButton(
                                  onPressed: () {
                                    // _searchData(selectedMonth, selectedYear);
                                  },
                                  child: const Text('Cari'),
                                ),
                              ],
                            ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(onRefresh: () { return _refreshData(); },
                    child: SingleChildScrollView(child: _buildCards())),
                  ),
                ],
              )
        ],
      ),
      floatingActionButton: isCodeMasuk ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-laporan');
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ) : null
    );
  }


  Widget _buildCards() {
  Map<String, List<DataRow>> groupedData = {};
  for (var dataRow in _rows) {
    final date = (dataRow.cells[1].child as Text).data!; // Assuming the date is in the second cell
    groupedData.putIfAbsent(date, () => []).add(dataRow);
  }
  List<Widget> cards = groupedData.entries.map((entry) {
    List<Widget> rowWidgets = entry.value.map((dataRow) {
      final cells = dataRow.cells;
      final id = (cells[0].child as Text).data!;
      final tgl = (cells[1].child as Text).data!;
      final jammulai = (cells[2].child as Text).data!;
      final jamselesai = (cells[3].child as Text).data!;
      final kegiatan = (cells[4].child as Text).data!;
      final status = (cells[5].child as Text).data!;
      IconData statusIcon;
      Color statusColor;
      switch (status) {
        case '1':
          statusIcon = Icons.check;
          statusColor = Colors.green;
          break;
        case '2':
          statusIcon = Icons.delete;
          statusColor = Colors.red;
          break;
        default:
          statusIcon = Icons.delete;
          statusColor = Colors.red;
      }

      IconData delIcon;
      switch (status) {
        case '1':
          delIcon = Icons.delete;
          break;
        case '2':
          delIcon = Icons.delete;
          break;
        default:
          delIcon = Icons.delete;
      }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  Text(jammulai),
                  const Icon(Icons.arrow_forward_outlined),
                  Text(jamselesai),
                ],
              ),
              selectedIndex == 0
                  ? CircleAvatar(
                      backgroundColor: statusColor,
                      radius: 12,
                      child: Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 15,
                      ),
                    )
                  : Column(
                      children: [
                        InkWell(
                          onTap: () {
                            navigateToEditLaporan({
                              'id': id,
                              'tgl': tgl,
                              'jammulai': jammulai,
                              'jamselesai': jamselesai,
                              'kegiatan': kegiatan,
                              'status': status,
                            });
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 15,
                            child: Icon(Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10,),
                         

                        InkWell(
                          onTap: () async {
                            bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Hapus'),
                              content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            _deleteLaporan(id);
                          }
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 15,
                            child: Icon(
                              delIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Text(kegiatan),
          ),
          const Divider(),
        ],
      );
    }).toList();
    var tgl = DateFormat('yyyy-MM-dd').parse(entry.key);
    var formattedDate = DateFormat('dd/MM/yyyy').format(tgl);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: $formattedDate'),
            ...rowWidgets,
          ],
        ),
      ),
    );
  }).toList();

  return Column(children: cards);
}
  List<DropdownMenuItem<String>> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) {
      return DropdownMenuItem<String>(
        value: (2018 + index).toString(),
        child: Text((2018 + index).toString()),
      );
    });
  }
}




