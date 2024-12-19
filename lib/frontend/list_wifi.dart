import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class ListWifi extends StatefulWidget {
  const ListWifi({Key? key}) : super(key: key);

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
        DateTime.now().difference(refrFetchTime!) < const Duration(seconds: 30)) {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Daftar Wifi', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadWifiData();
        },
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.wifi,
                          color: Colors.pink,
                          size: 24.0,
                          semanticLabel: 'Text to announce in accessibility modes',
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(' Daftar Wifi', style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ],
                    ),
                    SizedBox(
  width: 400,
  child: ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: wifiData.length,
    itemBuilder: (context, index) {
      var wifi = wifiData[index];
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
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
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.sync_rounded),
                label: Text(
                  _isLoading ? 'Loading...' : 'Syncron Data',
                  style: const TextStyle(fontSize: 14),
                ),
                onPressed: _isLoading ? null : _startLoading,
                style: ElevatedButton.styleFrom(fixedSize: const Size(140, 40)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> ambildata() async {
    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) < const Duration(minutes: 1)) {
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
      print('$url/api/wifi/$userAdmin');
      if (dataWifi.statusCode == 200) {
        List<dynamic> wifiData = json.decode(dataWifi.body)['data'];
        SpUtil.putString('wifi_data', json.encode(wifiData));
        if (mounted) {
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