import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/services/refresh.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class LaporanHarian extends StatefulWidget {
  const LaporanHarian({super.key});

  @override
  State<LaporanHarian> createState() => _LaporanHarianState();
}

class _LaporanHarianState extends State<LaporanHarian>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  List<dynamic> _riwayatLaporan = [];
  List<dynamic> _riwayatPengajuan = [];
  String? url = SpUtil.getString("url");
  String? idUser;
  late String selectedYear;
  late String selectedMonth;
  bool isLoading = true;
  bool value = false;
  List<DataRow> _rows = [];
  bool isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;

  void dataChange() {
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
    _fetchData();
    _refreshData();
    initializePreferences();
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
    const monthNumbers = {
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
    return monthNumbers[monthName] ?? '01';
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
          Text("Pengajuan LHK"),
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
          Text("Riwayat LHK"),
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
      String subUrl = '';
        subUrl = '$url/api/riwayat-lhk/$idUser/$selectedMonthNumber/$selectedYear';
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
            _riwayatLaporan = jsonData['data'];
        });

        if (jsonData.containsKey('data')) {
          final dataList = jsonData['data'] as List<dynamic>;

          setState(() {
            _rows = dataList.map((data) => DataRow(cells: [
                  DataCell(Text(data['id'].toString())),
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
      // print("Error fetching data: $e");
    }
  }
  Future<void> searchData(selectedMonth, selectedYear) async {
    final idUser = SpUtil.getString("id_user");
    String selectedMonthNumber = _getMonthNumber(selectedMonth);
    try {
      String subUrl = '';
        subUrl = '$url/api/riwayat-lhk/$idUser/$selectedMonthNumber/$selectedYear';
      final response = await http.get(
        Uri.parse(subUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
print(response.body);
        setState(() {
            _riwayatLaporan = jsonData['data'];
        });

        if (jsonData.containsKey('data')) {
          final dataList = jsonData['data'] as List<dynamic>;

          setState(() {
            _rows = dataList.map((data) => DataRow(cells: [
                  DataCell(Text(data['id'].toString())),
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
      // print("Error fetching data: $e");
    }
  }

  Future<void> _deleteLaporan(String id) async {
    final urlDel = '$url/api/delete-lhk/$id';

    try {
      final response = await http.delete(Uri.parse(urlDel));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = data["message"] ?? 'Laporan berhasil dihapus';
        if (mounted) {
          Alert.alertsuccess(context, message);
          _refreshData();
        }
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (error) {
      if (mounted) {
        Alert.alerterror(context, 'Error: $error');
      }
    }
  }

  Future<void> _refreshData() async {
    if (SyncLimiter.canSync()) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _fetchData();
        });
      }
    } else {
      Alert.alertwarning(context, "Refresh maksimal 3 kali dalam 1 menit!");
    }
  }

  void navigateToEditLaporan(Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLaporan(
          data: data,
          onUpdate: _refreshData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        Size size = MediaQuery.of(context).size;
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
  body: Stack(
    children: [
      // Background header that extends beyond what's visible
      Header().header(context),
      
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
                  const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Riwayat Laporan Harian',
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
                                  backgroundColor:
                                      const Color.fromARGB(255, 67, 60, 130),
                                ),
                                onPressed: () async {

                                  if (!isLoading) {

                                    setState(() {
                                      isLoading = true;
                                    });
                                    await Future.delayed(const Duration(seconds: 3));
                                  searchData(selectedMonth, selectedYear);
                                  }
                                },
                                child: const Text('Cari',
                                    style: TextStyle(
                                      color: Colors.white,
                                    )),
                              ),
                            ],
                          ),
          _buildCards()

                ],
              ),
            ),
          ),
        ],
      ),
    ],
  ),
      floatingActionButton:Transform.translate(
                  offset: const Offset(0, -20),
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/create-laporan');
                      if (result == true) {
                        setState(() {
                          _fetchData();
                        });
                      }
                    },
                    tooltip: 'Increment',
                    child: const Icon(Icons.add),
                  ),
                )
    );
    //   floatingActionButton: isCodeMasuk
    //           ? Transform.translate(
    //               offset: const Offset(0, -20),
    //               child: FloatingActionButton(
    //                 onPressed: () async {
    //                   final result = await Navigator.pushNamed(context, '/create-laporan');
    //                   if (result == true) {
    //                     setState(() {
    //                       _fetchData();
    //                     });
    //                   }
    //                 },
    //                 tooltip: 'Increment',
    //                 child: const Icon(Icons.add),
    //               ),
    //             )
    //           : null,
    // );
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

        bool isToday = tgl == DateFormat('yyyy-MM-dd').format(DateTime.now());
        DateTime jamMasukTime = DateFormat("HH:mm").parse(jammulai);
        DateTime jamPulangTime = DateFormat("HH:mm").parse(jamselesai);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue),
              Text(DateFormat("HH:mm").format(jamMasukTime)),
              SizedBox(width: 10,),
              const Icon(Icons.arrow_forward_outlined),
              SizedBox(width: 10,),
              Text(DateFormat("HH:mm").format(jamPulangTime)),
            ],
          ),
                if (isToday)
                  Row(
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
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
              Text(DateFormat('EEEE, dd/MM/yyyy', 'id').format(DateFormat('dd/MM/yyyy').parse(formattedDate)).toString()),
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