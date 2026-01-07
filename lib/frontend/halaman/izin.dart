import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/izin/detail_izin.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class IzinFront extends StatefulWidget {
  const IzinFront({super.key});

  @override
  State<IzinFront> createState() => _IzinFrontState();
}

class _IzinFrontState extends State<IzinFront> with TickerProviderStateMixin {
  List<dynamic> _riwayatPengajuan = [];
  List<dynamic> _riwayatIzin = [];

  String? url = SpUtil.getString("url");
  TabController? _controller;
  int selectedIndex = 0;
  late int selectedMonth = DateTime.now().month;
  late int selectedYear = DateTime.now().year;
  bool isLoading = true;
  bool value = false;
  List<DataRow> _rows = [];
  late Future<List<Map<String, dynamic>>> futureData;

  bool isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;
  bool _enabled = true;

  void dataChange() {
    setState(() {
      value = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _enabled = false;

    if (mounted) {
      _controller?.addListener(() {
        setState(() {
          _fetchData(selectedMonth, selectedYear);
        });
      });
      _fetchData(selectedMonth, selectedYear);
      _refreshData();
    }
  }

  Future<void> _fetchData(int selMonth, int selYear) async {
    // 1. Mulai Loading
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final int month = int.tryParse(selMonth.toString()) ?? DateTime.now().month;
    final int year = int.tryParse(selYear.toString()) ?? DateTime.now().year;
    final idUser = SpUtil.getString("id_user") ?? '';

    try {
      String subUrl = '';
      final monthStr = month.toString().padLeft(2, '0');
      final yearStr = year.toString();

      if (selectedIndex == 0) {
        subUrl = '$url/api/izin/riwayat-izin/pengajuan/$idUser/$monthStr/$yearStr';
      } else {
        subUrl = '$url/api/izin/riwayat-izin/$idUser/$monthStr/$yearStr';
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

        if (selectedIndex == 0) {
          if (jsonData.containsKey('data')) {
            final responseData = jsonData['data'];
            if (mounted) {
              setState(() {
                _riwayatPengajuan = responseData.cast<Map<String, dynamic>>();
                _controller?.animateTo(0);
              });
            }
          }
        } else {
          if (jsonData.containsKey('data')) {
            final dataList = jsonData['data'] as List<dynamic>;
            if (mounted) {
              setState(() {
                _riwayatIzin = dataList.cast<Map<String, dynamic>>();
                // Update _rows logic here if needed
                _controller?.animateTo(1);
              });
            }
          }
        }
      } else {
        // Handle jika status code bukan 200 (Opsional: Tampilkan snackbar)
        print("Gagal memuat data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
      // Handle error koneksi
    } finally {
      // 2. Stop Loading (Wajib dieksekusi apapun yang terjadi)
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _fetchData(selectedMonth, selectedYear);
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: size.width * 0.4,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedIndex == 0 ? Color.fromARGB(255, 67, 60, 130) : Colors.grey[300],
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (selectedIndex != 0) {
                                    // Cek agar tidak refresh jika sudah di tab ini (opsional)
                                    setState(() {
                                      selectedIndex = 0;
                                    });
                                    _fetchData(selectedMonth, selectedYear);
                                  }
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
                                  backgroundColor: selectedIndex == 1 ? Color.fromARGB(255, 67, 60, 130) : Colors.grey[300],
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (selectedIndex != 1) {
                                    setState(() {
                                      selectedIndex = 1;
                                    });
                                    _fetchData(selectedMonth, selectedYear);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      color: selectedIndex == 1 ? Colors.white : Colors.black87,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Riwayat",
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
                              child: DropdownButton<int>(
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
                                ].asMap().entries.map<DropdownMenuItem<int>>((entry) {
                                  final idx = entry.key; // 0..11
                                  final name = entry.value;
                                  return DropdownMenuItem<int>(
                                    value: idx + 1, // bulan sebagai angka 1..12
                                    child: Text(name),
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
                              child: DropdownButton<int>(
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
                              // Disable tombol jika sedang loading agar tidak bisa diklik double
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      _fetchData(selectedMonth, selectedYear);
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
                                      : const SizedBox(), // Hilangkan text 'Cari' jika loading, atau biarkan icon saja
                                  const Text(
                                    'Cari',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: selectedIndex == 0
                            ? RefreshIndicator(
                                onRefresh: _refreshData,
                                color: const Color.fromARGB(255, 67, 60, 130),
                                backgroundColor: Colors.white,
                                strokeWidth: 3,
                                child: Skeletonizer(
                                  enabled: isLoading,
                                  child: ListView.builder(
                                    itemCount: _riwayatPengajuan.length,
                                    itemBuilder: (context, index) {
                                      Text jenisStatus;

                                      switch (_riwayatPengajuan[index]['jenis_approval'].toString()) {
                                        case '2':
                                          jenisStatus = const Text('Dinas Luar ', style: TextStyle(color: Colors.black));
                                          break;
                                        case '3':
                                          jenisStatus = const Text('Izin ', style: TextStyle(color: Colors.black));
                                          break;
                                        case '4':
                                          jenisStatus = const Text('Sakit ', style: TextStyle(color: Colors.black));
                                          break;
                                        case '5':
                                          jenisStatus = const Text('IDLK ', style: TextStyle(color: Colors.black));
                                          break;
                                        case '6':
                                          jenisStatus = const Text('Cuti ', style: TextStyle(color: Colors.black));
                                          break;
                                        default:
                                          jenisStatus = const Text('Belum Disetujui ', style: TextStyle(color: Colors.black));
                                      }
                                      final status = (_riwayatPengajuan.length > index) ? _riwayatPengajuan[index]['status_approval'] : null;
                                      final izinTimestampStr = (_riwayatIzin.length > index) ? _riwayatIzin[index]['timestamp'] : null;
                                      final parsedTs = DateTime.tryParse(izinTimestampStr?.toString() ?? '');
                                      bool canDelete = false;
                                      if (status == 1) {
                                        if (parsedTs == null) {
                                          canDelete = true;
                                        } else {
                                          canDelete = parsedTs.isAfter(DateTime.now());
                                        }
                                      } else if (status == 5) {
                                        if (parsedTs != null && parsedTs.isAfter(DateTime.now())) {
                                          canDelete = true;
                                        }
                                      }
                                      return InkWell(
                                        onTap: () {
                                          navigateToDetailPage(_riwayatPengajuan[index], (_riwayatPengajuan[index]['no_urut']));
                                        },
                                        splashColor: const Color.fromARGB(60, 179, 2, 218),
                                        highlightColor: Colors.white10,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8, right: 8),
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
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  DateFormat('EEEE, dd/MM/yyyy', 'id').format(DateTime.parse(_riwayatPengajuan[index]['tgl_group'].toString())),
                                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    jenisStatus,
                                                                    if (_riwayatPengajuan[index]['id_keterangan'] != null && _riwayatPengajuan[index]['tgl_group'] == DateTime.now().toString())
                                                                      const Chip(
                                                                        padding: EdgeInsets.all(0),
                                                                        backgroundColor: Colors.red,
                                                                        label: Text('Pulang Cepat', style: TextStyle(color: Colors.white)),
                                                                      ),
                                                                  ],
                                                                ),
                                                                Text(
                                                                  '${_riwayatPengajuan[index]['durasi']} Hari',
                                                                  style: const TextStyle(color: Colors.black),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Column(
                                                          children: [
                                                            if (canDelete)
                                                              IconButton(
                                                                padding: EdgeInsets.zero,
                                                                icon: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors.red,
                                                                  size: 30,
                                                                ),
                                                                onPressed: () {
                                                                  var id = _riwayatPengajuan[index]['id_approval'].toString();
                                                                  var statusJenis = _riwayatPengajuan[index]['jenis_approval'].toString();
                                                                  _confirmDelete(id, statusJenis);
                                                                },
                                                              )
                                                            else if (_riwayatPengajuan[index]['status_approval'] == 3)
                                                              IconButton(
                                                                padding: EdgeInsets.zero,
                                                                icon: const Icon(
                                                                  Icons.close,
                                                                  color: Colors.red,
                                                                  size: 30,
                                                                ),
                                                                onPressed: () {
                                                                  var id = _riwayatPengajuan[index]['id_approval'].toString();
                                                                  var statusJenis = _riwayatPengajuan[index]['jenis_approval'].toString();
                                                                  _confirmDelete(id, statusJenis);
                                                                },
                                                              )
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
                            : _buildCards(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            // Pindahkan offset (-10, -120) langsung ke sini
            // bottom: 0 + 120, right: 0 + 10
            bottom: 120,
            right: 10,
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/buat_izin');
                if (result == true) {
                  setState(() {
                    _fetchData(selectedMonth, selectedYear);
                  });
                }
              },
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return ListView.builder(
      itemCount: _riwayatIzin.length,
      itemBuilder: (context, index) {
        Text jenisStatus;

        switch (_riwayatIzin[index]['jenis_approval'].toString()) {
          case '2':
            jenisStatus = const Text('Dinas Luar ', style: TextStyle(color: Colors.black));
            break;
          case '3':
            jenisStatus = const Text('Izin ', style: TextStyle(color: Colors.black));
            break;
          case '4':
            jenisStatus = const Text('Sakit ', style: TextStyle(color: Colors.black));
            break;
          case '5':
            jenisStatus = const Text('IDLK ', style: TextStyle(color: Colors.black));
            break;
          case '6':
            jenisStatus = const Text('Cuti ', style: TextStyle(color: Colors.black));
            break;
          default:
            jenisStatus = const Text('Belum Disetujui ', style: TextStyle(color: Colors.black));
        }

        return Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
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
                      onTap: () => navigateToDetailPage(_riwayatIzin[index], (_riwayatIzin[index]['no_urut'])),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd/MM/yyyy', 'id').format(DateTime.parse(_riwayatIzin[index]['tgl_group'].toString())),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      jenisStatus,
                                      if (_riwayatIzin[index]['id_keterangan'] != null && _riwayatIzin[index]['tgl_absen'] == DateTime.now().toString())
                                        const Chip(
                                          padding: EdgeInsets.all(0),
                                          backgroundColor: Colors.red,
                                          label: Text('Pulang Cepat', style: TextStyle(color: Colors.white)),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${_riwayatIzin[index]['durasi']} Hari',
                                    style: const TextStyle(color: Colors.black),
                                  )
                                ],
                              ),
                            ),
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
    );
  }

  // Fungsi untuk mengkonfirmasi penghapusan data
  void _confirmDelete(id, statusJenis) {
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
                _deleteItem(id, statusJenis);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus data
  Future<void> _deleteItem(id, statusJenis) async {
    final idUser = SpUtil.getString("id_user") ?? '';
    final urlDel = '$url/api/izin/hapus-izin/$idUser/$id';
    try {
      final response = await http.get(Uri.parse(urlDel));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (statusJenis == '5') {
          SpUtil.putBool('is_IDLK', false);
          SpUtil.putString('status_idlk', '-');
          SpUtil.putBool('is_PulangCepat', false);
        }
        SpUtil.putBool('is_PulangCepat', false);
        String message = json.encode(data["message"]).replaceAll('"', '');
        if (mounted) {
          setState(() {
            Alert.alertsuccess(context, message);
            _refreshData();
          });
        }
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

  List<DropdownMenuItem<int>> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) {
      final year = 2018 + index;
      return DropdownMenuItem<int>(
        value: year,
        child: Text(year.toString()),
      );
    });
  }
}
