import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage>
    with TickerProviderStateMixin {
  List<dynamic> _riwayatLaporan = [];
  List<dynamic> _riwayatIzin = [];

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
      if (selectedIndex == 0) {
        subUrl = '$url/api/izin/riwayat-izin/pengajuan/$idUser/$selectedMonthNumber/$selectedYear';
      } else {
        subUrl = '$url/api/riwayat-lhk/pengajuan/$idUser/$selectedMonthNumber/$selectedYear';
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
            final List<dynamic> responseData = json.decode(response.body)['data'];
            
            if (mounted) {
              setState(() {
              _riwayatIzin = responseData;
              _controller?.animateTo(0);
              isLoading = false;
            _riwayatIzin = responseData.cast<Map<String, dynamic>>();
            });
            }
            
          } 
          if (selectedIndex == 1) {
            _riwayatLaporan = jsonData['data'];
            if (mounted) {
              setState(() {
                _riwayatLaporan = jsonData['data'];
                _controller?.animateTo(1);
                isLoading = false;
              });
            }
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
          }
        });

        
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
  
  Future<void> _searchData(selectedIndex, selectedMonth, selectedYear) async {
    final idUser = SpUtil.getString("id_user");
    String selectedMonthNumber = _getMonthNumber(selectedMonth);
    try {
      String subUrl = '';
      if (selectedIndex == 0) {
        subUrl = '$url/api/izin/riwayat-izin/pengajuan/$idUser/$selectedMonthNumber/$selectedYear';
      } else {
        subUrl = '$url/api/riwayat-lhk/pengajuan/$idUser/$selectedMonthNumber/$selectedYear';
      }
      final response = await http.get(
        Uri.parse(subUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      print(response.statusCode);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          if (selectedIndex == 0) {
            _riwayatLaporan = jsonData['data'];
          } else {
            _riwayatIzin = jsonData['data'];
          }
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
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil dimuat'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }
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
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memuat data'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
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
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _fetchData();
        });
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
    return Scaffold(
      body: Stack(
        children: [
          Header(),
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
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 50, 50, 50),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: size.width * 0.4,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedIndex == 0
                                      ? Color.fromARGB(255, 67, 60, 130)
                                      : Colors.grey[300],
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedIndex = 0;
                                  });
                                  _fetchData();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.envelope,
                                      color: selectedIndex == 0 ? Colors.white : Colors.black87,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Pengajuan",
                                      style: TextStyle(
                                        color: selectedIndex == 0 ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: size.width * 0.4,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedIndex == 1
                                      ? Color.fromARGB(255, 67, 60, 130)
                                      : Colors.grey[300],
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedIndex = 1;
                                  });
                                  _fetchData();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      color: selectedIndex == 1 ? Colors.white : Colors.black87,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "LHK",
                                      style: TextStyle(
                                        color: selectedIndex == 1 ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F4FD),
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                              onPressed: () async {
                                if (!isLoading) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await Future.delayed(const Duration(seconds: 2));
                                  _searchData(selectedIndex, selectedMonth, selectedYear);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isLoading
                                    ? Container(
                                        width: 16,
                                        height: 16,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : 
                                  const Text('Cari',
                                    style: TextStyle(
                                      color: Colors.white,
                                    )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                              if(selectedIndex == 0)

                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshData,
                          color: const Color.fromARGB(255, 67, 60, 130),
                          backgroundColor: Colors.white,
                          strokeWidth: 3,
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
                          
                              return InkWell(
                                onTap: () {
                                  navigateToDetailPage(
                                      _riwayatIzin[index],
                                      (_riwayatIzin[index]['no_urut']));
                                },
                                splashColor: const Color.fromARGB(60, 179, 2, 218),
                                highlightColor: Colors.white10,
                                child: Padding(
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
                                                                        ['tgl_group'] ==
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
                                                      IconButton(
                                                        padding: EdgeInsets.zero,
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 30,
                                                        ),
                                                        onPressed: () => _confirmDelete(
                                                            _riwayatIzin[index]
                                                                ['id_approval']),
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
                        ),
                      )
                      else
                      _buildCards(),
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

  Widget _buildCards() {
  Map<String, List<DataRow>> groupedData = {};
  for (var dataRow in _rows) {
    final date = (dataRow.cells[1].child as Text).data!; // Assuming the date is in the second cell
    groupedData.putIfAbsent(date, () => []).add(dataRow);
  }

  List<Widget> cards = groupedData.entries.map((entry) {
    final reportDate = DateFormat('yyyy-MM-dd').parse(entry.key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Only date part
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    // Get the last day of the current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Condition to enable edit/delete
    // The report date must be greater than or equal to 3 days ago from today AND
    // the report date must be before or on the last day of the current month.
    bool canModify = !reportDate.isBefore(threeDaysAgo) && !reportDate.isAfter(lastDayOfMonth);

    Color cardColor = canModify ? Colors.white : Colors.grey[300]!; // Normal or disabled card color
    Color textColor = canModify ? Colors.black : Colors.grey[600]!; // Normal or disabled text color

    List<Widget> rowWidgets = entry.value.map((dataRow) {
      final cells = dataRow.cells;
      final id = (cells[0].child as Text).data!;
      final tgl = (cells[1].child as Text).data!;
      final jammulai = (cells[2].child as Text).data!;
      final jamselesai = (cells[3].child as Text).data!;
      final kegiatan = (cells[4].child as Text).data!;
      final status = (cells[5].child as Text).data!;

      DateTime jamMasukTime = DateFormat("HH:mm").parse(jammulai);
      DateTime jamPulangTime = DateFormat("HH:mm").parse(jamselesai);
                DateTime tglDateTime = DateFormat('yyyy-MM-dd').parse(tgl);

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: canModify ? Colors.blue : textColor),
                  Text(DateFormat("HH:mm").format(jamMasukTime), style: TextStyle(color: textColor)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_outlined, color: canModify ? null : textColor),
                  const SizedBox(width: 8),
                  Text(DateFormat("HH:mm").format(jamPulangTime), style: TextStyle(color: textColor)),
                ],
              ),
              if (canModify || status == '2')

Row(
  children: [
    InkWell(
      onTap: () {
        if (tglDateTime.month == DateTime.now().month && tglDateTime.year == DateTime.now().year) {
          navigateToEditLaporan({
            'id': id,
            'tgl': tgl,
            'jammulai': jammulai,
            'jamselesai': jamselesai,
            'kegiatan': kegiatan,
            'status': status,
          });
        }
      },
      child: CircleAvatar(
        backgroundColor: tglDateTime.month == DateTime.now().month && tglDateTime.year == DateTime.now().year ? Colors.green : Colors.red,
        radius: 15,
        child: Icon(
          tglDateTime.month == DateTime.now().month && tglDateTime.year == DateTime.now().year ? Icons.edit : Icons.close,
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
      
      child: tglDateTime.month == DateTime.now().month && tglDateTime.year == DateTime.now().year
  ? CircleAvatar(
      backgroundColor: Colors.red,
      radius: 15,
      child: Icon(
        Icons.delete,
        color: Colors.white,
        size: 20,
      ),
    )
  : SizedBox.shrink(),
    ),
  ],
)
            ],
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Text(kegiatan, style: TextStyle(color: textColor)),
          ),
          Divider(color: textColor.withOpacity(0.5)), // Adjust divider color
        ],
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.all(8),
      color: cardColor, // Apply card color
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'id').format(reportDate),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), // Apply text color
            ),
            ...rowWidgets,
          ],
        ),
      ),
    );
  }).toList();

  return Column(children: cards);
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
    return List.generate(currentYear - 2018 + 1, (index) {
      return DropdownMenuItem<String>(
        value: (2018 + index).toString(),
        child: Text((2018 + index).toString()),
      );
    });
  }
}