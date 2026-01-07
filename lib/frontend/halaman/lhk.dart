import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class LhkFront extends StatefulWidget {
  const LhkFront({super.key});

  @override
  State<LhkFront> createState() => _LhkFrontState();
}

class _LhkFrontState extends State<LhkFront> with TickerProviderStateMixin {
  List<dynamic> _riwayatPengajuan = [];
  List<dynamic> _riwayatLaporan = [];

  String? url;
  String? idUser;
  int selectedIndex = 0;
  late String selectedYear;
  late String selectedMonth;
  bool isLoading = true;
  bool isCodeMasuk = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth = _getMonthName(now.month);

    initializeData();
  }

  Future<void> initializeData() async {
    await SpUtil.getInstance();
    if (mounted) {
      setState(() {
        url = SpUtil.getString("url");
        idUser = SpUtil.getString("id_user");
        isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;
      });
      _fetchData();
    }
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

  Future<void> _fetchData() async {
    if (url == null || idUser == null) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    String selectedMonthNumber = _getMonthNumber(selectedMonth);
    String subUrl = '';

    if (selectedIndex == 0) {
      subUrl = '$url/api/riwayat-lhk/pengajuan/$idUser/$selectedMonthNumber/$selectedYear';
    } else {
      subUrl = '$url/api/riwayat-lhk/$idUser/$selectedMonthNumber/$selectedYear';
    }

    try {
      final response = await http.get(
        Uri.parse(subUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);

        List<dynamic> parsedList = [];

        if (decodedBody is Map<String, dynamic>) {
          if (decodedBody.containsKey('data')) {
            var innerData = decodedBody['data'];

            if (innerData is List) {
              parsedList = innerData;
            } else if (innerData is Map<String, dynamic>) {
              if (innerData.containsKey('data') && innerData['data'] is List) {
                parsedList = innerData['data'];
              } else {
                parsedList = innerData.values.toList();
              }
            } else {
              print("Warning: 'data' is not List or Map.");
            }
          } else {
            parsedList = [
              decodedBody
            ];
          }
        } else if (decodedBody is List) {
          parsedList = decodedBody;
        }

        if (mounted) {
          setState(() {
            if (selectedIndex == 0) {
              _riwayatPengajuan = parsedList.cast<Map<String, dynamic>>();
            } else {
              _riwayatLaporan = parsedList.cast<Map<String, dynamic>>();
            }
          });
        }
      } else {
        print("Gagal request: ${response.statusCode}");
      }
    } catch (e) {
      print("CRITICAL ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteLaporan(String id) async {
    setState(() => isLoading = true);

    final urlDel = '$url/api/delete-lhk/$id';

    try {
      final response = await http.delete(Uri.parse(urlDel));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = data["message"] ?? 'Laporan berhasil dihapus';
        if (mounted) {
          Alert.alertsuccess(context, message);
          _fetchData();
        }
      } else {
        throw Exception('Gagal menghapus laporan');
      }
    } catch (error) {
      if (mounted) {
        Alert.alerterror(context, 'Error: $error');
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchData();
  }

  void navigateToEditLaporan(Map<String, dynamic> data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLaporan(
          data: data,
          onUpdate: () {},
        ),
      ),
    );
    if (result != null || true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          const Header(),
          Column(
            children: [
              SizedBox(height: size.height * 0.15),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
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
                            _buildTabButton(0, "Pengajuan", FontAwesomeIcons.fileLines),
                            _buildTabButton(1, "Riwayat", Icons.history_rounded),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildDropdown(
                                value: selectedMonth,
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
                                ],
                                onChanged: (val) => setState(() => selectedMonth = val!),
                                hint: 'Bulan',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildDropdown(
                                value: selectedYear,
                                items: _getYearItems(),
                                onChanged: (val) => setState(() => selectedYear = val!),
                                hint: 'Tahun',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 67, 60, 130),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: isLoading ? null : _fetchData,
                              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Cari', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: const Color.fromARGB(255, 67, 60, 130),
                          child: Skeletonizer(
                            enabled: isLoading,
                            child: selectedIndex == 0 ? _buildCardsPengajuan() : _buildCards(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isCodeMasuk)
            Positioned(
              bottom: 120,
              right: 10,
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/create-laporan');
                  if (result == true) {
                    _fetchData();
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isSelected = selectedIndex == index;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? const Color.fromARGB(255, 67, 60, 130) : Colors.grey[300],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (selectedIndex != index) {
            setState(() {
              selectedIndex = index;
            });
            _fetchData();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCards() {
    if (_riwayatLaporan.isEmpty && !isLoading) {
      return const Center(child: Text("Tidak ada data riwayat"));
    }

    Map<String, List<dynamic>> groupedData = {};
    for (var data in _riwayatLaporan) {
      final date = data['tgl'] ?? '';
      if (groupedData[date] == null) groupedData[date] = [];
      groupedData[date]!.add(data);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        String dateKey = groupedData.keys.elementAt(index);
        List<dynamic> items = groupedData[dateKey]!;

        DateTime? parsedDate;
        try {
          parsedDate = DateFormat('yyyy-MM-dd').parse(dateKey);
        } catch (e) {
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsedDate != null ? DateFormat('EEEE, dd/MM/yyyy', 'id').format(parsedDate) : dateKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...items.map((item) {
                  final jammulai = item['jammulai'] ?? '-';
                  final jamselesai = item['jamselesai'] ?? '-';
                  final kegiatan = item['rincian_kegiatan'] ?? '-';
                  final status = item['status'].toString();

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue, size: 16),
                              const SizedBox(width: 4),
                              Text(jammulai),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16),
                              const SizedBox(width: 8),
                              Text(jamselesai),
                            ],
                          ),
                          Icon(
                            status == '1' ? Icons.check_circle : Icons.sync,
                            color: status == '1' ? Colors.green : Colors.blue,
                            size: 20,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(kegiatan),
                      ),
                      const Divider(),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardsPengajuan() {
    if (_riwayatPengajuan.isEmpty && !isLoading) {
      return const Center(child: Text("Tidak ada data pengajuan"));
    }

    Map<String, List<dynamic>> groupedData = {};
    for (var data in _riwayatPengajuan) {
      final date = data['tgl'] ?? '';
      if (groupedData[date] == null) groupedData[date] = [];
      groupedData[date]!.add(data);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        String dateKey = groupedData.keys.elementAt(index);
        List<dynamic> items = groupedData[dateKey]!;

        DateTime reportDate;
        try {
          reportDate = DateFormat('yyyy-MM-dd').parse(dateKey);
        } catch (e) {
          reportDate = DateTime.now();
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final threeDaysAgo = today.subtract(const Duration(days: 1));
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        bool canModify = !reportDate.isBefore(threeDaysAgo) && !reportDate.isAfter(lastDayOfMonth);
        Color cardColor = canModify ? Colors.white : Colors.grey[200]!;
        Color textColor = canModify ? Colors.black : Colors.grey[600]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'id').format(reportDate),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Divider(),
                ...items.map((item) {
                  final id = item['id'].toString();
                  final jammulai = item['jammulai'] ?? '-';
                  final jamselesai = item['jamselesai'] ?? '-';
                  final kegiatan = item['rincian_kegiatan'] ?? '-';
                  final status = item['status'].toString();

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: canModify ? Colors.blue : textColor, size: 16),
                              const SizedBox(width: 4),
                              Text(jammulai, style: TextStyle(color: textColor)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: textColor, size: 16),
                              const SizedBox(width: 8),
                              Text(jamselesai, style: TextStyle(color: textColor)),
                            ],
                          ),
                          if (canModify || status == '2')
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    navigateToEditLaporan(item);
                                  },
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 14,
                                    child: Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    _confirmDelete(id);
                                  },
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 14,
                                    child: Icon(Icons.delete, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(kegiatan, style: TextStyle(color: textColor)),
                      ),
                      Divider(color: textColor.withOpacity(0.2)),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLaporan(id);
              },
            ),
          ],
        );
      },
    );
  }

  List<String> _getYearItems() {
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - 2018 + 1, (index) {
      return (2018 + index).toString();
    });
  }
}
