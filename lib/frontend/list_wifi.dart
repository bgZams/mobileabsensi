import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class ListWifi extends StatefulWidget {
  const ListWifi({super.key});

  @override
  State<ListWifi> createState() => _ListWifiState();
}

class _ListWifiState extends State<ListWifi> {
  List<Map<String, dynamic>> wifiData = [];
  bool _isLoading = false;
  var userAdmin = SpUtil.getString("username_admin");
  var url = SpUtil.getString("url");
  DateTime? lastFetchTime;
  DateTime? refrFetchTime;

  @override
  void initState() {
    super.initState();
    loadWifiData();
  }

  Future<void> loadWifiData() async {
    String wifiDataJson = SpUtil.getString("wifi_data") ?? '[]';
    if (refrFetchTime != null &&
        DateTime.now().difference(refrFetchTime!) <
            const Duration(seconds: 30)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: "Refresh minimal 30 detik sekali!",
      );
    }
    if (wifiDataJson.isNotEmpty) {
      List<dynamic> decodedData = json.decode(wifiDataJson);
      wifiData = List<Map<String, dynamic>>.from(decodedData);
      refrFetchTime = DateTime.now();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _startLoading() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await ambildata();
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        Size size = MediaQuery.of(context).size;
    return Scaffold(
  body: Stack(
    children: [
      WidgetNavbar(title: 'List Wifi'),
      Column(
        children: [
          SizedBox(height: size.height * 0.15),
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.wifi,
                              color: Colors.black,
                              size: 24.0,
                              semanticLabel:
                                  'Daftar Wifi',
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: Text(' Daftar Wifi',
                                  style: TextStyle(color: Colors.black,fontSize: 20),),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: wifiData.length,
                            itemBuilder: (context, index) {
                              var wifi = wifiData[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0F4FD),
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.wifi, color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        wifi['SSID'],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.sync_rounded,color: Colors.white),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Syncron Wifi',
                        style: const TextStyle(fontSize: 16,color: Colors.white),
                      ),
                      onPressed: _isLoading ? null : _startLoading,
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(140, 50),
                        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
                      ),
                    ),
                  ),
                  // Add more content elements here
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

  Future<void> ambildata() async {
    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) <
            const Duration(minutes: 1)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Alert.alertinfo(context, "Syncron data minimal 1 menit sekali!");
      }
      return;
    }

    try {
      http.Response dataWifi = await http.get(
        Uri.parse('$url/api/wifi/$userAdmin'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json'
        },
      );

      if (dataWifi.statusCode == 200) {
        List<dynamic> newWifiData = json.decode(dataWifi.body)['data'];
        // Simpan ke SharedPreferences
        SpUtil.putString('wifi_data', json.encode(newWifiData));

        // Update state dengan data baru
        if (mounted) {
          setState(() {
            wifiData = List<Map<String, dynamic>>.from(newWifiData);
          });
          Alert.alertsuccess(context, "Syncron berhasil.");
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, "Syncron gagal.");
        }
      }

      lastFetchTime = DateTime.now();
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi!");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
