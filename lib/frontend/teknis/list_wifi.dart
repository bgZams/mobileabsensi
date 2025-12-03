import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:sp_util/sp_util.dart';
import 'package:mobileabsensi/frontend/teknis/wifi_list_screen.dart';

class WifiOpd extends StatefulWidget {
  const WifiOpd({super.key});

  @override
  State<WifiOpd> createState() => _WifiOpdState();
}

class _WifiOpdState extends State<WifiOpd> {
  late final String url = SpUtil.getString("url") ?? '';
  bool isLoading = false;
  
  // List utama data OPD
  List<Map<String, dynamic>> opdData = [];
  
  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    getOpdData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Getter untuk mendapatkan list yang sudah difilter berdasarkan pencarian
  List<Map<String, dynamic>> get filteredOpdData {
    if (_searchKeyword.isEmpty) {
      return opdData;
    }
    return opdData.where((opd) {
      return opd['name'].toLowerCase().contains(_searchKeyword.toLowerCase());
    }).toList();
  }

  Future<void> getOpdData() async {
    setState(() {
      isLoading = true;
    });

    try {
      http.Response dataOpd = await http.get(
        Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/get_admin_opd.php'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (dataOpd.statusCode == 200) {
        List<dynamic> opdJson = json.decode(dataOpd.body)['data'];
        
        if (mounted) {
          List<Map<String, dynamic>> tempOpdList = [];
          
          for (var opd in opdJson) {
            if (opd['id_server'] != '0') {
              // Masukkan data awal, wifi_count kita set null dulu (sebagai tanda loading)
              tempOpdList.add({
                'username': opd['username'],
                'name': opd['nama_instansi'],
                'wifi_count': null, // null artinya belum di-load
              });
            }
          }

          // Tampilkan list OPD segera agar user tidak menunggu lama
          setState(() {
            opdData = tempOpdList;
            isLoading = false; 
          });

          // Jalankan proses pengambilan jumlah wifi di background
          _fetchWifiCountsInBackground();
        }
      } else {
        if (mounted) Alert.alerterror(context, "Gagal mendapatkan data OPD.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi!");
      setState(() => isLoading = false);
    }
  }

  // Fungsi baru untuk mengambil data wifi satu per satu dan mengupdate UI secara real-time
  Future<void> _fetchWifiCountsInBackground() async {
    for (int i = 0; i < opdData.length; i++) {
      if (!mounted) return;
      
      String username = opdData[i]['username'];
      int count = await getWifiCount(username);

      // Update data spesifik di index tersebut
      setState(() {
        opdData[i]['wifi_count'] = count;
      });
    }
  }

  Future<int> getWifiCount(String username) async {
    try {
      http.Response dataWifi = await http.get(
        Uri.parse('$url/api/wifi/$username'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (dataWifi.statusCode == 200) {
        List<dynamic> wifiDataJson = json.decode(dataWifi.body)['data'];
        return wifiDataJson.length;
      }
    } catch (e) {
      // Error handling silent
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          WidgetNavbar(title: 'List Wifi OPD'),
          Column(
            children: [
              SizedBox(height: size.height * 0.13), // Sesuaikan tinggi agar navbar terlihat
              
              // --- Bagian Search Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Cari Instansi / OPD...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              // -------------------------

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
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOpdData.isEmpty 
                        ? const Center(child: Text("Data tidak ditemukan"))
                        : ListView.builder(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                          itemCount: filteredOpdData.length,
                          itemBuilder: (context, index) {
                            var opd = filteredOpdData[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 236, 246, 255),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.apartment, color: Color.fromARGB(255, 17, 110, 160)),
                                ),
                                title: Text(
                                  opd['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wifi, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      // Logika tampilan jumlah Wifi
                                      opd['wifi_count'] == null
                                          ? const SizedBox(
                                              width: 12, 
                                              height: 12, 
                                              child: CircularProgressIndicator(strokeWidth: 2)
                                            ) // Loading kecil jika data belum ada
                                          : Text('Jumlah WiFi: ${opd['wifi_count']}'),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WifiListScreen(
                                        opdName: opd['name'],
                                        opdUsername: opd['username'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}