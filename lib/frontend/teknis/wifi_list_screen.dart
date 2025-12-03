import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'package:sp_util/sp_util.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WifiListScreen extends StatefulWidget {
  final String opdName;
  final String opdUsername;

  const WifiListScreen({super.key, required this.opdName, required this.opdUsername});

  @override
  State<WifiListScreen> createState() => _WifiListScreenState();
}

class _WifiListScreenState extends State<WifiListScreen> {
  late final String url = SpUtil.getString("url") ?? '';
  final NetworkInfo _networkInfo = NetworkInfo();
  String? wifiName, wifiBSSID, wifiIPv4;
  List<Map<String, dynamic>> wifiData = [];
  bool isLoading = false;
  String _connectionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    searchData();
  }

  Future<void> _initNetworkInfo() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
          wifiBSSID = await _networkInfo.getWifiBSSID();
          wifiIPv4 = await _networkInfo.getWifiIP();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
          wifiBSSID = 'Unauthorized to get Wifi BSSID';
          wifiIPv4 = 'Unauthorized to get Wifi IPv4';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
        wifiBSSID = await _networkInfo.getWifiBSSID();
        wifiIPv4 = await _networkInfo.getWifiIP();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get network info', error: e);
      wifiName = 'Failed to get Wifi Name';
      wifiBSSID = 'Failed to get Wifi BSSID';
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    if (mounted) {
      setState(() {
        _connectionStatus = 'Nama WiFi: ${wifiName?.replaceAll('"', '')}\n'
            'BSSID: $wifiBSSID\n'
            'IP Address: $wifiIPv4';
      });
    }
  }

  Future<void> searchData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      http.Response dataWifi = await http.get(
        Uri.parse('$url/api/wifi/${widget.opdUsername}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
     
      if (dataWifi.statusCode == 200) {
        List<dynamic> wifiDataJson = json.decode(dataWifi.body)['data'];
        if (mounted) {
          setState(() {
            wifiData = List<Map<String, dynamic>>.from(wifiDataJson);
          });
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, "Gagal mencari data wifi.");
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, "Gagal mengambil data. Periksa koneksi internet.");
      }
    }finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> simpanWifi() async {
    setState(() {
      isLoading = true;
    });

    try {
      http.Response dataWifi = await http.post(
        Uri.parse('$url/api/wifi/simpan'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'SSID': wifiName?.replaceAll('"', ''),
          'BSSID': wifiBSSID,
          'ip_address': wifiIPv4,
          'admin': widget.opdUsername,
          'id_admin_instansi': SpUtil.getString('id_admin_instansi'),
          'nama_instansi': SpUtil.getString('nama_instansi'),
        }),
      );

      var data = json.decode(dataWifi.body);
print(data);
      if (dataWifi.statusCode == 200) {
        if (mounted) {
          Alert.alertsuccess(context, data['message']);
          searchData(); // Refresh list setelah menyimpan
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, data['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, "Terjadi kesalahan koneksi, Coba lagi! $e ");
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
      http.Response dataWifi = await http.delete(
        Uri.parse('$url/api/wifi/${SpUtil.getString('id_user')}/delete/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (dataWifi.statusCode == 200) {
        if (mounted) {
          Alert.alertsuccess(context, "Data berhasil dihapus.");
          searchData(); // Refresh list setelah menghapus
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, "Data gagal dihapus.");
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
        title: Text('WiFi ${widget.opdName}'),
        backgroundColor: const Color.fromARGB(255, 17, 110, 160),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
  padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 80.0),
  itemCount: wifiData.length,
  itemBuilder: (context, index) {
    var wifi = wifiData[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListTile(
        title: Text(
          wifi['SSID'] ?? 'Nama WiFi tidak diketahui',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BSSID: ${wifi['BSSID']}'),
            Text('IP: ${wifi['ip_address']}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            showConfirmation(
              context,
              "Hapus WiFi",
              "Apakah Anda yakin ingin menghapus data WiFi ini?",
              () => deleteWifi(wifi['id'].toString()),
            );
          },
        ),
      ),
    );
  },
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddWifiDialog(context);
        },
        label: const Text('Tambahkan WiFi'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 17, 110, 160),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddWifiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah WiFi Baru'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Informasi WiFi:'),
                const SizedBox(height: 10),
                Text(_connectionStatus),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                Navigator.of(context).pop();
                simpanWifi();
              },
            ),
          ],
        );
      },
    );
  }
  // Di dalam class Alert
static void showConfirmation(BuildContext context, String title, String content, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Ya, Hapus'),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
    },
  );
}
}