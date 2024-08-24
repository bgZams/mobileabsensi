import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/frontend/teknis/pending_wifi.dart';
import 'dart:developer' as developer;
import 'package:mobileabsensi/services/alert.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sp_util/sp_util.dart';

class WifiOpd extends StatefulWidget {
  const WifiOpd({Key? key}) : super(key: key);

  @override
  State<WifiOpd> createState() => _WifiOpdState();
}

class _WifiOpdState extends State<WifiOpd> {
  late final String url = SpUtil.getString("url") ?? '';
  late final String idUser = SpUtil.getString("id_user") ?? '';
  final NetworkInfo _networkInfo = NetworkInfo();
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
  String _connectionStatus = 'Unknown';
  String? selectedAdmin;
  List<Map<String, dynamic>> adminList = [];
  String? selectedUsername = 'admin.diskominfo';
  String? selectedIdServer = '1';

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    getAdmin();
    searchData(selectedUsername!,selectedIdServer!);
  }

  Future<void> getAdmin() async {
  setState(() {
    isLoading = true;
  });
  try {
    http.Response dataAdmin = await http.get(
      Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/get_admin_opd.php'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (dataAdmin.statusCode == 200) {
      List<dynamic> adminJson = json.decode(dataAdmin.body)['data'];
      setState(() {
        // Filter adminList untuk hanya menyertakan admin dengan id_server tidak null
        adminList = List<Map<String, dynamic>>.from(
          adminJson.where((admin) => admin['id_server'] != '0').map((admin) => {
            'username': admin['username'],
            'id_server': admin['id_server'],
            'name': admin['nama_instansi']
          })
        );
      });
    } else {
      if (mounted) {
        Alert.alerterror(context, "Gagal mendapatkan data admin.");
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


  Future<void> searchData(String username, String idServer) async {
    setState(() {
      isLoading = true;
    });

    try {
      var opd = username.isEmpty ? 'admin.diskominfo' : username;
      http.Response dataWifi = await http.get(
        Uri.parse('$url/api/wifi/$opd'),
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

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteWifi(String serverName, String id) async {
    setState(() {
      isLoading = true;
    });
    var opd = selectedUsername ?? 'admin.diskominfo';
    try {
      http.Response dataWifi = await http.delete(
        Uri.parse('$url/api/wifi/$idUser/delete/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (dataWifi.statusCode == 200) {
        setState(() {
          wifiData.removeWhere((wifi) => wifi['id'] == id);
          searchData(opd, serverName);
        });
        if (mounted) {
          Alert.alertsuccess(context, "Data berhasil di hapus.");
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, "Data gagal di hapus.");
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

  Widget _buildDropdownAdmin() {
  return DropdownButtonFormField<String>(
    decoration: const InputDecoration(
      labelText: 'Nama Admin',
    ),
    elevation: 5,
    value: selectedAdmin,
    hint: const Text("Pilih nama admin"),
    items: adminList.map((admin) {
      return DropdownMenuItem<String>(
        value: admin['username'],
        child: SizedBox(
          width: 280,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200.0),
            child: SingleChildScrollView(
              child: Text(
                admin['name'],
                softWrap: true,
              ),
            ),
          ),
        ),
      );
    }).toList(),
    onChanged: (String? value) {
      setState(() {
        selectedAdmin = value;
        selectedUsername = adminList.firstWhere((admin) => admin['username'] == value)['username'];
        selectedIdServer = adminList.firstWhere((admin) => admin['username'] == value)['id_server'];
      });
    },
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Nama admin tidak boleh kosong';
      }
      return null;
    },
  );
}



  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          icon: isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.search_rounded, size: 20,color:Colors.white),
          label: Text(
            isLoading ? 'Loading...' : 'Cari',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black,
                  offset: Offset(1, 1),
                )
              ],
            ),
          ),
          onPressed: isLoading ? null : () => searchData(selectedUsername ?? '', selectedIdServer ?? ''),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 17, 110, 160),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initNetworkInfo() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = 'Unauthorized to get Wifi BSSID';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }
    var ssid = wifiName?.replaceAll('"', '');
    setState(() {
      _connectionStatus = 'Wifi Name: $ssid\n'
          'Wifi BSSID: $wifiBSSID\n'
          'Wifi IPv4: $wifiIPv4\n'
          'Wifi IPv6: $wifiIPv6\n'
          'Wifi Broadcast: $wifiBroadcast\n'
          'Wifi Gateway: $wifiGatewayIP\n'
          'Wifi Submask: $wifiSubmask\n';
    });
  }

  Future<void> simpanWifi() async {
    setState(() {
      isLoading = true;
    });

    var opd = selectedUsername ?? 'admin.diskominfo';
    var server = serverName.text;

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
          'admin': opd,
        }),
      );
        var data = json.decode(dataWifi.body);

      if (dataWifi.statusCode == 200) {
        setState(() {
          wifiData.add({
            'SSID': wifiName?.replaceAll('"', ''),
            'BSSID': wifiBSSID,
            'ip_address': wifiIPv4,
            'admin': opd,
          });
        });

        if (mounted) {
          Alert.alertsuccess(context, data['message']);
          setState(() {
            searchData(opd, server);
          });
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

        title: const Text('List Wifi OPD',style: TextStyle(color: Colors.white),),
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
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildDropdownAdmin(),
                    _buildSaveButton(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WifiPendding())),
                child: SizedBox(
                  width: 50,
                  child: Container(
                    color: const Color.fromARGB(255, 255, 247, 201),
                                  padding: const EdgeInsets.all(8.0),
                                  child:
                    const Icon(Icons.pending_actions,size: 25,color: Color.fromARGB(255, 152, 137, 0),),),
                ),
              ),
            ),
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
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.wifi,
                                color: Colors.pink,
                                size: 24.0,
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
                                  title: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          var id = wifi['id'].toString();
                                          deleteWifi(serverName.text, id);
                                        },
                                        child: const Icon(Icons.delete, size: 30, color: Colors.red),
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
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -20),
        child: FloatingActionButton(
          onPressed: () async {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Tambah Wifi'),
                  content: SizedBox(
                    height: 150,
                    width: MediaQuery.of(context).size.width,
                    child: Text(_connectionStatus),
                  ),
                  actions: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text('Simpan'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await simpanWifi();
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text('Batal'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
