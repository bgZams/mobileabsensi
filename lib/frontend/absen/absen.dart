import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/absen/pulang_cepat.dart';
import 'package:mobileabsensi/frontend/absen/widget_header.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/izin/riwayat_pengajuan.dart';
import 'package:mobileabsensi/frontend/navigasi.dart';
import 'package:mobileabsensi/services/refresh.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sp_util/sp_util.dart';

import '../../services/alert.dart';

class Absen extends StatefulWidget {
  const Absen({Key? key}) : super(key: key);

  @override
  State<Absen> createState() => _AbsenState();
}

class _AbsenState extends State<Absen> {
  final StreamController<String> _jlhIzinController =
      StreamController<String>();
  Timer? _timer;
  String? url = SpUtil.getString("url");
  String _jamSekarang = '';
  List<Map<String, dynamic>> wifiData = [];
  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isLoading = false;
  bool _isMasuk = false;
  bool _isPulang = false;

  String? wifiName = '';
  String? wifiBSSID = '';
  String? wifiIPv4;

  String? jamMasuk;
  String? jamPulang;
  String? code;
  bool isCodeMasuk = false;
  bool isCodePulang = false;
  bool isPulangCepat = false;
  String? idUser = SpUtil.getString("id_user");
  String? idAdmin = SpUtil.getString("id_admin_instansi") ?? '';
  String? admin = SpUtil.getString("username_admin") ?? '';
  String? nama = SpUtil.getString("nama_lengkap").toString();
  String? instansi = SpUtil.getString("nama_instansi").toString();

  String? notif = '0';
  DateTime? lastFetchTime;
  int syncCount = 0;

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    _jamSekarang = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getCurrentTime());
    loadWifiData();
    setState(() {
      isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;
      isCodePulang = SpUtil.getBool('is_codePulang') ?? false;
      isPulangCepat = SpUtil.getBool('is_PulangCepat') ?? false;
    });

    _jlhIzinController.add(SpUtil.getInt("jlh_izin").toString());
    _simulateDataUpdate();
    _fetchNotif();
    refreshData();
    if (SpUtil.getInt('idlk') == 1) {
      _checkIdlk();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _jlhIzinController.close();
    super.dispose();
  }

  void _getCurrentTime() {
    if (mounted) {
      setState(() {
        _jamSekarang = _formatDateTime(DateTime.now());
      });
    }
  }

  void _simulateDataUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      var updatedJlhIzin = SpUtil.getInt("jlh_izin").toString();
      if (!_jlhIzinController.isClosed) {
        _jlhIzinController.add(updatedJlhIzin);
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  Future<void> loadWifiData() async {
    String wifiDataJson = SpUtil.getString("wifi_data") ?? '[]';
    if (wifiDataJson.isNotEmpty) {
      List<dynamic> decodedData = json.decode(wifiDataJson);
      wifiData = List<Map<String, dynamic>>.from(decodedData);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      wifiName = await _networkInfo.getWifiName();
      wifiBSSID = await _networkInfo.getWifiBSSID();
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wi-Fi Name or BSSID', error: e);
      wifiName = 'Failed to get Wi-Fi Name';
      wifiBSSID = 'Failed to get Wi-Fi BSSID';
    }
  }

  Future<void> absenMasuk(String? wifiName, String? wifiBSSID) async {
    String connectedSSID = wifiName ?? '';
    String ssID = connectedSSID.replaceAll('"', '');
    String connectedBSSID = wifiBSSID ?? '';
    var listWifiString = SpUtil.getString("wifi_data");

    if (listWifiString != null) {
      List<dynamic> listWifi = jsonDecode(listWifiString);
      bool isWifiMatch = listWifi.any(
          (wifi) => wifi['SSID'] == ssID && wifi['BSSID'] == connectedBSSID);

      if (isWifiMatch) {
        if (SpUtil.getString("id_user") != null) {
          try {
            var datamasuk = {
              'id_user': idUser,
              'id_admin_instansi': idAdmin,
              'nama_lengkap': nama,
              'ssid': connectedSSID,
              'bssid': connectedBSSID,
              'versi': '1.4'
            };
            http.Response absenMasuk = await http.post(
              Uri.parse('$url/api/masuk'),
              body: datamasuk,
            );

            await Future.delayed(const Duration(seconds: 2));
            if (absenMasuk.statusCode == 200) {
              if (mounted) {
                final data = jsonDecode(absenMasuk.body);
                String message =
                    json.encode(data["message"]).replaceAll('"', '');
                if (data["code"] == "wifi" ||
                    data["code"] == "versi_app" ||
                    data["code"] == "unknown") {
                  Alert.alertwarning(context, message);
                } else if (data["code"] == "1" || data["code"] == "2") {
                  code = data['code']?.toString();
                  String waktuJson = data['waktu'];
                  DateTime waktuText = DateTime.parse(waktuJson);
                  SpUtil.putString(
                      'saved_date', DateFormat('yyyy-MM-dd').format(waktuText));
                  jamMasuk = DateFormat('HH:mm').format(waktuText);
                  SpUtil.putString('masuk', '$jamMasuk');
                  SpUtil.putBool('is_codeMasuk', true);

                  Alert.alertsuccess(context, message);

                  setState(() {
                    isCodeMasuk = true;
                  });
                } else {
                  Alert.alertinfo(context, message);

                  setState(() {
                    isCodeMasuk = false;
                  });
                }
              } else {
                throw Exception('Kesalahan HTTP: ${absenMasuk.statusCode}');
              }
            }
          } catch (e) {
            Alert.alerterror(context, 'Gagal mengambil absen!');
          }
        }
      } else {
        Alert.alertwarning(context, 'SSID tidak ditemukan dalam daftar WiFi!');
      }
    } else {
      Alert.alerterror(context, 'Gagal mengambil absen!');
    }
  }

  Future<void> absenPulang(String? wifiName, String? wifiBSSID) async {
    if (isPulangCepat == true) {
      Alert.alertwarning(context,
          'Sedang mengajukan Pulang Cepat \nHapus pengajuan untuk mengambil absen pulang');
      return;
    }

    if (SpUtil.getInt('status_idlk') == 1) {
      try {
        var datapulang = {
          'id_user': idUser,
          'id_admin_instansi': idAdmin,
          'ssid': 'IDLK',
          'bssid': 'IDLK',
          'versi': '1.4'
        };
        http.Response absenPulang = await http.put(
          Uri.parse('$url/api/pulang/$idUser'),
          body: jsonEncode(datapulang),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (absenPulang.statusCode == 200) {
          if (mounted) {
            final data = jsonDecode(absenPulang.body);
            code = data['code']?.toString();
            String message = json.encode(data["message"]).replaceAll('"', '');
            if (data["code"] == "1") {
              SpUtil.putString('code_pulang', code!);
              String waktuJson = data['waktu'];
              DateTime waktuText = DateTime.parse(waktuJson);
              jamPulang = DateFormat('HH:mm').format(waktuText);
              SpUtil.putString('pulang', '$jamPulang');
              SpUtil.putInt('idlk', 0);
              SpUtil.putInt('status_idlk', 0);
              SpUtil.putString('pulang', '$jamMasuk');
              SpUtil.putBool('is_codePulang', true);
              Alert.alertsuccess(context, message);
              setState(() {
                isCodePulang = true;
                isPulangCepat = false;
              });
            } else {
              Alert.alertwarning(context, message);
            }
          }
        } else {
          if (mounted) {
            Alert.alertwarning(context, 'Tidak dapat terhubung ke server');
          }
        }
      } catch (e) {
        if (mounted) {
          Alert.alerterror(context, 'Gagal mengambil absen!');
        }
      }
      return;
    }

    String connectedSSID = wifiName ?? '';
    String ssID = connectedSSID.replaceAll('"', '');
    String connectedBSSID = wifiBSSID ?? '';
    if (SpUtil.getString("id_user") != null) {
      try {
        var listWifiString = SpUtil.getString("wifi_data");
        if (listWifiString != null) {
          List<dynamic> listWifi = jsonDecode(listWifiString);
          bool isWifiMatch = listWifi.any((wifi) =>
              wifi['SSID'] == ssID && wifi['BSSID'] == connectedBSSID);

          if (isWifiMatch) {
            var datapulang = {
              'id_user': idUser,
              'id_admin_instansi': idAdmin,
              'ssid': ssID,
              'bssid': connectedBSSID,
              'versi': '1.4'
            };
            http.Response absenPulang = await http.put(
              Uri.parse('$url/api/pulang/$idUser'),
              body: jsonEncode(datapulang),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
            );

            if (absenPulang.statusCode == 200) {
              if (mounted) {
                final data = jsonDecode(absenPulang.body);
                code = data['code']?.toString();
                String message =
                    json.encode(data["message"]).replaceAll('"', '');
                if (data["code"] == "1") {
                  SpUtil.putString('code_pulang', code!);
                  String waktuJson = data['waktu'];
                  DateTime waktuText = DateTime.parse(waktuJson);
                  jamPulang = DateFormat('HH:mm').format(waktuText);
                  SpUtil.putString('pulang', '$jamPulang');
                  SpUtil.putBool('is_codePulang', true);
                  Alert.alertsuccess(context, message);
                  setState(() {
                    isCodePulang = true;
                    isPulangCepat = false;
                  });
                } else {
                  Alert.alertwarning(context, message);
                }
              }
            } else {
              if (mounted) {
                Alert.alertwarning(context, 'Tidak dapat terhubung ke server');
              }
            }
          } else {
            Alert.alertwarning(
                context, 'SSID tidak ditemukan dalam daftar WiFi!');
          }
        } else {
          Alert.alerterror(context, 'Gagal mengambil absen!');
        }
      } catch (e) {
        if (mounted) {
          Alert.alerterror(context, 'Gagal mengambil absen!');
        }
      }
    }
  }

  Future<void> _checkIdlk() async {
    try {
      final idlk = await http.get(
        Uri.parse('$url/api/notif/get-notif-count/$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (idlk.statusCode == 200) {
        if (mounted) {
          setState(() {
            SpUtil.putInt('status_idlk', 1);
            SpUtil.putInt('idlk', 0);
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _fetchNotif() async {
    if (idUser!.isEmpty || url!.isEmpty) {
      debugPrint('Error: idUser or url is empty');
      return;
    }

    try {
      final responseIzin = await http.get(
        Uri.parse('$url/api/notif/get-notif-count/$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (responseIzin.statusCode == 200) {
        if (mounted) {
          setState(() {
            final data = jsonDecode(responseIzin.body);
            notif = data["tot_Notif"].toString();
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> refreshData() async {
    // print(isCodePulang);
 
    if (SyncLimiter.canSync() && mounted) {
      await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _getCurrentTime();
          _initNetworkInfo();
          _fetchNotif();
          _isLoading = false;
        });
        
    } else {
      Alert.alertwarning(context, "Refresh maksimal 3 kali dalam 1 menit!");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    var namaSSID = wifiName.toString().replaceAll('"', '');
    return Scaffold(
  body: RefreshIndicator(
    onRefresh: () async {
      await refreshData();
    },
    child: SizedBox(
      height: deviceHeight * 1.2,
      child: Container(
        color: const Color.fromARGB(255, 238, 238, 238),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: size.height * .3,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    alignment: Alignment.topCenter,
                    image: AssetImage('assets/images/imgheader.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Navigasi()),
                                      );
                                    },
                                    child: const CircleAvatar(
                                      radius: 32,
                                      backgroundImage: AssetImage(
                                          'assets/images/profile.png'),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 180,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(instansi ?? '',
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  StreamBuilder<String>(
                                    stream: _jlhIzinController.stream,
                                    builder: (context, snapshot) {
                                      return IconButton(
                                        icon: SizedBox(
                                          width: 60,
                                          height: 30,
                                          child: Stack(
                                            alignment: Alignment.bottomLeft,
                                            children: [
                                              const Icon(Icons.notifications),
                                              if (snapshot.hasData &&
                                                  snapshot.data != null)
                                                Positioned(
                                                  right: 28,
                                                  top: 0,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                    child: Text(
                                                      notif ?? '0',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const KonfirmasiIzin(),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ),
                            Header().headerMenu(context),
                            const SizedBox(height: 20),
                            Container(
                                color: Colors.white,
                                width: deviceWidth,
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 190,
                                      alignment: Alignment.center,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          namaSSID,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 31, 31),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color.fromARGB(
                                                255, 141, 151, 0)),
                                        color: const Color.fromARGB(
                                            255, 248, 255, 147),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(
                                                255, 141, 151, 0),
                                            spreadRadius: 1,
                                            blurRadius: 1,
                                          )
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Color.fromARGB(
                                              255, 141, 151, 0),
                                        ),
                                        onPressed: () {
                                          _initNetworkInfo();
                                        },
                                      ),
                                    ),
                                  ],
                                )),
                            Container(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: deviceWidth,
                              padding: const EdgeInsets.all(2.0),
                            ),
                            Container(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              width: deviceWidth,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(_jamSekarang,
                                            style: const TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 14, 60, 129),
                                            )),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                            DateFormat('E, dd/MM/yyyy')
                                                .format(DateTime.now()),
                                            style: const TextStyle(
                                                fontSize: 25)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 20),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(left: 40),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            //TOMBOL MASUK PULANG
                                            Column(
                                              children: [
                                                DateTime.now()
                                                            .toIso8601String()
                                                            .substring(0, 10) ==
                                                        SpUtil.getString(
                                                            'saved_date')
                                                    ? Column(
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  173,
                                                                  218,
                                                                  255),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            width: 100,
                                                            height: 100,
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "${SpUtil.getString('masuk')}",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 30,
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        2,
                                                                        53,
                                                                        95),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 25),
                                                        ],
                                                      )
                                                    : GestureDetector(
                                                        onTap: _isLoading
                                                            ? null
                                                            : () async {
                                                                setState(() {
                                                                  _isMasuk =
                                                                      true;
                                                                });

                                                                await _initNetworkInfo();

                                                                if (wifiName !=
                                                                        null &&
                                                                    wifiBSSID !=
                                                                        null &&
                                                                    wifiName!
                                                                        .isNotEmpty &&
                                                                    wifiBSSID!
                                                                        .isNotEmpty) {
                                                                  await absenMasuk(
                                                                      wifiName,
                                                                      wifiBSSID);
                                                                } else {
                                                                  Alert.alertwarning(
                                                                      context,
                                                                      'Silahkan sambungkan ke Wifi!');
                                                                }

                                                                setState(() {
                                                                  _isMasuk =
                                                                      false;
                                                                });
                                                              },
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _isMasuk
                                                                ? const CircularProgressIndicator()
                                                                : Column(
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                            100,
                                                                        child: Image.asset(
                                                                            'assets/images/sidikjari1new.png'),
                                                                      ),
                                                                      const Text(
                                                                        "Masuk",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      )
                                                                    ],
                                                                  ),
                                                          ],
                                                        ),
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(width: 45),
                                            Column(
                                              children: [
                                                isCodePulang
                                                    ? Column(
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  173,
                                                                  218,
                                                                  255),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            width: 100,
                                                            height: 100,
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                                "${SpUtil.getString('pulang')}",
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        30,
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            2,
                                                                            53,
                                                                            95))),
                                                          ),
                                                          const SizedBox(
                                                              height: 25),
                                                        ],
                                                      )
                                                    : GestureDetector(
                                                        onTap: _isLoading
                                                            ? null
                                                            : () async {
                                                                setState(() {
                                                                  _isPulang =
                                                                      true;
                                                                });

                                                                if (isCodeMasuk ==
                                                                    false) {
                                                                  QuickAlert
                                                                      .show(
                                                                    context:
                                                                        context,
                                                                    type: QuickAlertType
                                                                        .warning,
                                                                    text:
                                                                        "Belum mengambil absen masuk!",
                                                                  );
                                                                } else {
                                                                  await _initNetworkInfo();
                                                                  if (SpUtil.getInt(
                                                                          'status_idlk') ==
                                                                      1) {
                                                                    // Tidak perlu WiFi jika status_idlk adalah 1
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        return AlertDialog(
                                                                          title: const Text('Yakin ingin absen pulang?',style: TextStyle(fontSize: 15),),

                                                                          // content:
                                                                          //     SizedBox(
                                                                          //   height:
                                                                          //       50,
                                                                          //   width:
                                                                          //       MediaQuery.of(context).size.width,
                                                                          //   child:
                                                                          //       const Text('Yakin ingin absen pulang'),
                                                                          // ),
                                                                          actions: <
                                                                              Widget>[
                                                                            TextButton(
                                                                              style: TextButton.styleFrom(
                                                                                textStyle: Theme.of(context).textTheme.labelLarge,
                                                                                backgroundColor: Colors.green,
                                                                              ),
                                                                              child: const Text(
                                                                                'Pulang',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                              onPressed: () async {
                                                                                Navigator.of(context).pop();
                                                                                await absenPulang('IDLK', 'IDLK'); // Tidak perlu WiFi
                                                                              },
                                                                            ),
                                                                            TextButton(
                                                                              style: TextButton.styleFrom(
                                                                                  textStyle: Theme.of(context).textTheme.labelLarge,
                                                                                  backgroundColor: Colors.red),
                                                                              child: const Text(
                                                                                'Batal',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                  } else if (wifiName !=
                                                                          null &&
                                                                      wifiBSSID !=
                                                                          null &&
                                                                      wifiName!
                                                                          .isNotEmpty &&
                                                                      wifiBSSID!
                                                                          .isNotEmpty) {
                                                                    // Jika WiFi tersedia, gunakan WiFi untuk absen
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        return AlertDialog(
                                                                          title:
                                                                              const Text('Yakin ingin absen pulang?',style: TextStyle(fontSize: 15),),
                                                                          // content:
                                                                          //     SizedBox(
                                                                          //   height:
                                                                          //       50,
                                                                          //   width:
                                                                          //       MediaQuery.of(context).size.width,
                                                                          //   child:
                                                                          //       const Text('Yakin ingin absen pulang'),
                                                                          // ),
                                                                          actions: <
                                                                              Widget>[
                                                                            TextButton(
                                                                              style: TextButton.styleFrom(
                                                                                textStyle: Theme.of(context).textTheme.labelLarge,
                                                                                backgroundColor: Colors.green,
                                                                              ),
                                                                              child: const Text(
                                                                                'Pulang',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                              onPressed: () async {
                                                                                Navigator.of(context).pop();
                                                                                await absenPulang(wifiName, wifiBSSID); // Menggunakan WiFi
                                                                              },
                                                                            ),
                                                                            TextButton(
                                                                              style: TextButton.styleFrom(
                                                                                  textStyle: Theme.of(context).textTheme.labelLarge,
                                                                                  backgroundColor: Colors.red),
                                                                              child: const Text(
                                                                                'Batal',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                              },
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                  } else {
                                                                    // Jika tidak memenuhi kondisi, tampilkan peringatan
                                                                    Alert.alertwarning(
                                                                        context,
                                                                        'Silahkan sambungkan ke Wifi!');
                                                                  }
                                                                }

                                                                setState(() {
                                                                  _isPulang =
                                                                      false;
                                                                });
                                                              },
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _isPulang
                                                                ? const CircularProgressIndicator()
                                                                : Column(
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                            100,
                                                                        child: Image.asset(
                                                                            'assets/images/sidikjari2new.png'),
                                                                      ),
                                                                      if (SpUtil.getInt(
                                                                              'status_idlk') ==
                                                                          1)
                                                                        const Text(
                                                                          "IDLK",
                                                                          style: TextStyle(
                                                                              fontSize: 18,
                                                                              fontWeight: FontWeight.bold),
                                                                        )
                                                                      else
                                                                        const Text(
                                                                          "Pulang",
                                                                          style: TextStyle(
                                                                              fontSize: 18,
                                                                              fontWeight: FontWeight.bold),
                                                                        )
                                                                    ],
                                                                  )
                                                          ],
                                                        ),
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(width: 45),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SpUtil.getBool('is_codeMasuk') == true
                                            ? SpUtil.getBool('is_codePulang') == false
                                                ? SpUtil.getBool('is_PulangCepat') == true
                                                    ? Column(
                                                        children: [
                                                          Center(
                                                              child:
                                                                  ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const RiwayatPengajuanIzin()),
                                                              );
                                                            },
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      173,
                                                                      218,
                                                                      255),
                                                            ),
                                                            child: const Text(
                                                                'Status Pengajuan',
                                                                style: TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            0,
                                                                            162,
                                                                            255))),
                                                          )),
                                                          const SizedBox(
                                                            height: 20,
                                                          )
                                                        ],
                                                      )
                                                    : Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 8),
                                                        child: Center(
                                                          child:
                                                              ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const PulangCepat()),
                                                              );
                                                            },
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                            child: const Text(
                                                              ' Pulang Cepat ',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                : Container()
                                            : Container(),
                                      ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
