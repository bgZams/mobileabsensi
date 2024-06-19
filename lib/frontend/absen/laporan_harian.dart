import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
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
  bool _isLoading = true;
  List<DataRow> _rows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);
    _fetchData();
    _controller = TabController(length: list.length, vsync: this);
    _controller?.addListener(() {
      setState(() {
        selectedIndex = _controller!.index;
      });
    _fetchData();
      print("Selected Index: ${_controller?.index}");
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
      }else{
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
        _processData(response);
        if (jsonData.containsKey('data')) {
          final dataList = jsonData['data'] as List<dynamic>;
          setState(() {
            _rows = dataList.map((data) => DataRow(cells: [
              DataCell(Text(data['tgl'])),
              DataCell(Text(data['jammulai'])),
              DataCell(Text(data['jamselesai'])),
              DataCell(Text(data['rincian_kegiatan'])),
              DataCell(Text(data['status'])),
            ])).toList();
            _isLoading = false;
          });
        } else {
          _isLoading = false;
          throw Exception('Failed to load data');
        }
      } else {
        _isLoading = false;
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processData(http.Response response) {
    setState(() {
      _riwayatLaporan = json.decode(response.body)['data'];
    });
  }

  Future<void> _sendRejection(int id, String alasan) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/lhk/tolak/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'alasan': alasan}),
      );

      if (response.statusCode == 200) {
        setState(() {
          selectedIndex = 1; // Set index to LHK tab
          _controller?.animateTo(1); // Move to LHK tab
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil ditolak')),
        );

        _refreshData();
      } else {
        throw Exception('Failed to reject izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _sendAcception(int id) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/lhk/terima/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          selectedIndex = 1; // Set index to LHK tab
          _controller?.animateTo(1); // Move to LHK tab
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        _fetchData();
      } else {
        throw Exception('Gagal menyetujui izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Laporan Harian')),
        elevation: 4,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-laporan');
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }


  void _showRejectDialog(int id) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Masukkan alasan"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // TextButton(
              // child: const Text('Kirim'),
              // onPressed: () {
              //   String alasan = controller.text;
              //   if (alasan.isNotEmpty) {
              //     _sendRejection(id, alasan);
              //     Navigator.of(context).pop();
              //   } else {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Alasan tidak boleh kosong')),
              //     );
              //   }
              // },
            // ),
          ],
        );
      },
    );
  }

  Widget _buildCards() {
    Map<String, List<DataRow>> groupedData = {};
    for (var dataRow in _rows) {
      final date = (dataRow.cells[0].child as Text).data!;
      groupedData.putIfAbsent(date, () => []).add(dataRow);
    }
    List<Widget> cards = groupedData.entries.map((entry) {
      List<Widget> rowWidgets = entry.value.map((dataRow) {
        final cells = dataRow.cells;
        final startTime = (cells[1].child as Text).data!;
        final endTime = (cells[2].child as Text).data!;
        final activity = (cells[3].child as Text).data!;
        final status = (cells[4].child as Text).data!;
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
                    Text(startTime),
                    const Icon(Icons.arrow_forward_outlined),
                    Text(endTime),
                  ],
                ),
              selectedIndex == 0 ? CircleAvatar(
                      backgroundColor: statusColor,
                              radius: 12,
                              child: Icon(
                                statusIcon,
                                color: Colors.white,
                                size: 15,
                              ),
                    ) : Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  const EditLaporan(
                              ),
                            ),);
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
                          onTap: () {
                            _showRejectDialog(3);
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
              child: Text(activity),
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




