import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'package:sp_util/sp_util.dart';

class WifiPendding extends StatefulWidget {
  const WifiPendding({Key? key}) : super(key: key);

  @override
  State<WifiPendding> createState() => _WifiPenddingState();
}

class _WifiPenddingState extends State<WifiPendding> {
  late final String url = SpUtil.getString("url") ?? '';
  late final String idUser = SpUtil.getString("id_user") ?? '';
  String? wifiName,
        wifiBSSID,
        wifiIPv4,
        wifiIPv6,
        wifiGatewayIP,
        wifiBroadcast,
        wifiSubmask;

  List<Map<String, dynamic>> wifiData = [];
  final TextEditingController serverName = TextEditingController();
  bool isLoading = false;
  String? selectedAdmin;
  List<Map<String, dynamic>> adminList = [];
  String? selectedUsername;
  String? selectedIdServer;

  @override
  void initState() {
    super.initState();
    searchData();
  }

  Future<void> searchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      http.Response dataWifi = await http.get(
        Uri.parse('$url/api/wifi/p/pengajuan'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (dataWifi.statusCode == 200) {
        List<dynamic> wifiDataJson = json.decode(dataWifi.body)['data'];
        setState(() {
          wifiData = List<Map<String, dynamic>>.from(wifiDataJson);
        });
      } else {
        if (mounted) {
          Alert.alerterror(context, "Gagal mencari data wifi.");
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi!");
      }
    }
      if (mounted) {

    setState(() {
      isLoading = false;
    });
      }
  }

  Future<void> terimaWifi(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      http.Response dataWifi = await http.put(
        Uri.parse('$url/api/wifi/terima/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      var data = json.decode(dataWifi.body);
      if (dataWifi.statusCode == 200) {
        setState(() {
          wifiData.removeWhere((wifi) => wifi['id'] == id);
          searchData();
        });
        if (mounted) {
          Alert.alertsuccess(context, data['message']);
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, data['message']);
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

  Future<void> deleteWifi(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      http.Response dataWifi = await http.put(
        Uri.parse('$url/api/wifi/$idUser/tolak/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      var data = json.decode(dataWifi.body);
      if (dataWifi.statusCode == 200) {
        setState(() {
          wifiData.removeWhere((wifi) => wifi['id'] == id);
          searchData();
        });
        if (mounted) {
          Alert.alertsuccess(context, data['message']);
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, data['message']);
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),

        title: const Text('Pengajuan Wifi',style: TextStyle(color: Colors.white),),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 228, 224, 224),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 400,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: wifiData.length,
                              itemBuilder: (context, index) {
                                var wifi = wifiData[index];
                                return ListTile(
                                  title: Row(
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            color: Colors.green,
                                            child: InkWell(
                                              onTap: () {
                                                var id = wifi['id'].toString();
                                                terimaWifi(id);
                                              },
                                              child: const Icon(Icons.check, size: 35, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(height: 5,),
                                          Container(
                                            color: Colors.red,

                                            child: InkWell(
                                              onTap: () {
                                                var id = wifi['id'].toString();
                                                deleteWifi(id);
                                              },
                                              child: const Icon(Icons.close, size: 35, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20,),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(wifi['SSID']),
                                          Text(wifi['BSSID']),
                                          Text(wifi['ip_address']),
                                        ],
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
