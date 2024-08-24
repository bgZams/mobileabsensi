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
        DateTime.now().difference(refrFetchTime!) <
            const Duration(minutes: 1)) {
      setState(() {
        _isLoading = false;
      });
      return QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: "Refresh minimal 1 menit sekali!",
      );
    }
    if (wifiDataJson.isNotEmpty) {
      List<dynamic> decodedData = json.decode(wifiDataJson);
      wifiData = List<Map<String, dynamic>>.from(decodedData);
      refrFetchTime = DateTime.now();
    }
    setState(() {

    });
  }

  void _startLoading() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ambildata();
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Daftar Wifi',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
         leading: IconButton(
              icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          loadWifiData();
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
                          semanticLabel:
                              'Text to announce in accessibility modes',
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(' Daftar Wifi',
                              style: Theme.of(context).textTheme.titleLarge),
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
                          return ListTile(
                            title: Text(wifi['SSID']),
                            subtitle: Text(wifi['nama_opd']),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.sync_rounded),
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
    setState(() {
      _isLoading = true;
    });

    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) <
            const Duration(minutes: 1)) {
      setState(() {
        _isLoading = false;
      });
      if(mounted){
          return Alert.alertinfo(context, "Syncron data minimal 1 menit sekali!");
        }
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
        List<dynamic> wifiData = json.decode(dataWifi.body);
        SpUtil.putString('wifi_data', json.encode(wifiData));
        if(mounted){
          Alert.alertsuccess(context, "Syncron berhasil.");
        }
      } else {
        if(mounted){
          Alert.alerterror(context, "Syncron gagal.");
        }
      }

      lastFetchTime = DateTime.now();
    } catch (e) {
      if(mounted){
          Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi!");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}
