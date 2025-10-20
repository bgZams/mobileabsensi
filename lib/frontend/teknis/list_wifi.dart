import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:sp_util/sp_util.dart';
import 'package:mobileabsensi/frontend/teknis/wifi_list_screen.dart'; // Import halaman baru

class WifiOpd extends StatefulWidget {
  const WifiOpd({super.key});

  @override
  State<WifiOpd> createState() => _WifiOpdState();
}

class _WifiOpdState extends State<WifiOpd> {
  late final String url = SpUtil.getString("url") ?? '';
  bool isLoading = false;
  List<Map<String, dynamic>> opdData = [];

  @override
  void initState() {
    super.initState();
    getOpdData();
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
          // Filter dan tambahkan jumlah WiFi ke setiap OPD
          List<Map<String, dynamic>> tempOpdList = [];
          for (var opd in opdJson) {
            if (opd['id_server'] != '0') {
              int wifiCount = await getWifiCount(opd['username']);
              tempOpdList.add({
                'username': opd['username'],
                'name': opd['nama_instansi'],
                'wifi_count': wifiCount,
              });
            }
          }

          setState(() {
            opdData = tempOpdList;
          });
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, "Gagal mendapatkan data OPD.");
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi!");
      }
    }
    setState(() {
      isLoading = false;
    });
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
      // Tangani error jika gagal mendapatkan jumlah WiFi
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
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 16.0),
                          itemCount: opdData.length,
                          itemBuilder: (context, index) {
                            var opd = opdData[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.apartment, color: Color.fromARGB(255, 17, 110, 160)),
                                title: Text(opd['name']),
                                subtitle: Text('Jumlah WiFi: ${opd['wifi_count']}'),
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