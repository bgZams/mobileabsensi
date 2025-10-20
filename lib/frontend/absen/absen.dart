import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/absen/pulang_cepat.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/widget/widget_fitur.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:quickalert/quickalert.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';
import '../../services/alert.dart';

class Absen extends StatefulWidget {
  const Absen({super.key});

  @override
  State<Absen> createState() => _AbsenState();
}

class _AbsenState extends State<Absen> {
  final PageController _pageController = PageController();
  bool _enabled = true;
  String? url = SpUtil.getString("url");
  List<Map<String, dynamic>> wifiData = [];
  bool _isMasuk = false;
  bool _isPulang = false;
  String? wifiName;
  String? wifiBSSID;
  String? wifiIPv4;
  Timer? _timer;
  final NetworkInfo _networkInfo = NetworkInfo();
  String? jamMasuk;
  String? jamPulang;
  String? code;
  bool isCodeMasuk = false;
  bool isCodePulang = false;
  bool isPulangCepat = false;
  bool isIDLK = false;
  String? idUser = SpUtil.getString("id_user");
  String? idAdmin = SpUtil.getString("id_admin_instansi") ?? '';
  String? admin = SpUtil.getString("username_admin") ?? '';
  String? nama = SpUtil.getString("nama_lengkap").toString();
  String? instansi = SpUtil.getString("nama_instansi").toString();
  String? notif = '0';
  DateTime? lastFetchTime;
  int syncCount = 0;

  // Tambahkan ValueNotifier untuk state yang sering berubah
  final ValueNotifier<String> _jamSekarangNotifier = ValueNotifier('');
  final ValueNotifier<String?> _wifiNameNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCodeMasukNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCodePulangNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isPulangCepatNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isIDLKNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _notifNotifier = ValueNotifier('0');

  @override
  void initState() {
    super.initState();
    _enabled = false;
    _initNetworkInfo();
    _startPeriodicCheck(); 
    if (SpUtil.getString('id_type') == "1") {
      cekDataShift();
    }

    if (SpUtil.getBool('is_PulangCepat') == true ||
        SpUtil.getBool('is_IDLK') == true) {
      _checkIdlkandPulangCepat();
    }
    _jamSekarangNotifier.value = _formatDateTime(DateTime.now());
    loadWifiData();

    // Inisialisasi notifiers
    _isCodeMasukNotifier.value = SpUtil.getBool('is_codeMasuk') ?? false;
    _isCodePulangNotifier.value = SpUtil.getBool('is_codePulang') ?? false;
    _isPulangCepatNotifier.value = SpUtil.getBool('is_PulangCepat') ?? false;
    _isIDLKNotifier.value = SpUtil.getBool('is_IDLK') ?? false;

    _fetchNotif();
    refreshData();

            print(SpUtil.getString('device_id'));
            // print('status_idlk ${SpUtil.getString("status_idlk")}');
            // print('is_codeMasuk ${SpUtil.getBool("is_codeMasuk")}');
            // print('is_codePulang ${SpUtil.getBool("is_codePulang")}');
            // print('is_PulangCepat ${SpUtil.getBool("is_PulangCepat")}');
            // print('is_IDLK ${SpUtil.getBool("is_IDLK")}');
            // print('_isMasuk ${SpUtil.getBool("_isMasuk")}');
            // print('_isPulang ${SpUtil.getBool("_isPulang")}');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    // Dispose semua notifiers
    _jamSekarangNotifier.dispose();
    _wifiNameNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isCodeMasukNotifier.dispose();
    _isCodePulangNotifier.dispose();
    _isPulangCepatNotifier.dispose();
    _isIDLKNotifier.dispose();
    _notifNotifier.dispose();
    super.dispose();
  }

  void _getCurrentTime() {
    if (mounted) {
      _jamSekarangNotifier.value = _formatDateTime(DateTime.now());
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  Future<void> cekDataShift() async {
    final dataShift = await http.get(
      Uri.parse(
          'http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/api/jam-kerja/${SpUtil.getString('id_user')}'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (dataShift.statusCode == 200) {
      final shiftData = json.decode(dataShift.body)['data'];
      SpUtil.putString('shift_data', json.encode(shiftData));
    } else {
      return;
    }
  }

  Future<void> loadWifiData() async {
    String wifiDataJson = SpUtil.getString("wifi_data") ?? '[]';
    if (wifiDataJson.isNotEmpty) {
      List<dynamic> decodedData = json.decode(wifiDataJson);
      wifiData = List<Map<String, dynamic>>.from(decodedData);
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkNetworkChanges();
      _getCurrentTime(); // Update waktu setiap 3 detik
    });
  }

  Future<void> _checkNetworkChanges() async {
    try {
      String? currentWifiName = await _networkInfo.getWifiName();
      String? cleanName = currentWifiName?.replaceAll('"', '');

      if (!mounted) return;

      if (cleanName != _wifiNameNotifier.value) {
        _wifiNameNotifier.value = cleanName;

        // Update other network info
        wifiBSSID = await _networkInfo.getWifiBSSID();
        wifiIPv4 = await _networkInfo.getWifiIP();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking network: $e');
      }
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      wifiName = await _networkInfo.getWifiName();
      wifiBSSID = await _networkInfo.getWifiBSSID();
      wifiIPv4 = await _networkInfo.getWifiIP();

      if (mounted) {
        _wifiNameNotifier.value = wifiName?.replaceAll('"', '');
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wi-Fi Name or BSSID', error: e);
      if (mounted) {
        _wifiNameNotifier.value = 'Failed to get Wi-Fi Name';
      }
    }
  }

  Future<void> absenMasuk(String? wifiName, String? wifiBSSID) async {
    if (!mounted) return;

    _isLoadingNotifier.value = true;

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
              'username': SpUtil.getString('username'),
              'instansi': SpUtil.getString('id_instansi'),
              'ssid': connectedSSID,
              'bssid': connectedBSSID,
              'versi': '1.4',
              'deviceId': SpUtil.getString('device_id'),
              'id_type': SpUtil.getString('id_type'),
            };

            http.Response absenMasuk = await http
                .post(
                  Uri.parse('$url/api/masuk'),
                  body: datamasuk,
                )
                .timeout(const Duration(seconds: 30));

            await Future.delayed(const Duration(seconds: 2));

            if (!mounted) return;

            if (absenMasuk.statusCode == 200) {
              final data = jsonDecode(absenMasuk.body);
              String message = json.encode(data["message"]).replaceAll('"', '');

              if (data["code"] == "wifi" ||
                  data["code"] == "versi_app" ||
                  data["code"] == "unknown") {
                if (mounted) Alert.alertwarning(context, message);
              } else if (data["code"] == "1" || data["code"] == "2") {
                code = data['code']?.toString();
                String waktuJson = data['waktu'];
                DateTime waktuText = DateTime.parse(waktuJson);
                SpUtil.putString(
                    'saved_date', DateFormat('yyyy-MM-dd').format(waktuText));
                jamMasuk = DateFormat('HH:mm').format(waktuText);
                SpUtil.putString('masuk', '$jamMasuk');
                SpUtil.putBool('is_codeMasuk', true);

                if (mounted) {
                  Alert.alertsuccess(context, message);
                  _isCodeMasukNotifier.value = true;
                }
              } else if (data["code"] == "5") {
                if (mounted) {
                  Alert.alertinfo(context, message);
                  _isCodeMasukNotifier.value = false;
                }
              } else {
                if (mounted) {
                  Alert.alertinfo(context, message);
                  _isCodeMasukNotifier.value = false;
                }
              }
            } else {
              throw Exception('Kesalahan HTTP: ${absenMasuk.statusCode}');
            }
          } catch (e) {
            if (mounted) {
              Alert.alerterror(context, 'Gagal mengambil absen!');
            }
          } finally {
            if (mounted) {
              _isLoadingNotifier.value = false;
            }
          }
        }
      } else {
        if (mounted) {
          Alert.alertwarning(
              context, 'SSID tidak ditemukan dalam daftar WiFi!. ');
          _isLoadingNotifier.value = false;
        }
      }
    } else {
      if (mounted) {
        Alert.alerterror(context, 'Gagal mengambil absen!');
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> absenPulang(String? wifiName, String? wifiBSSID) async {
    if (!mounted) return;

    _isLoadingNotifier.value = true;
    if (SpUtil.getBool('is_PulangCepat') == true &&
        SpUtil.getString('status_idlk') == '-' &&
        SpUtil.getString('statusPC') == 'pending') {
      if (mounted) {
        Alert.alertwarning(context,
            'Sedang mengajukan Pulang Cepat \nHapus pengajuan untuk mengambil absen pulang');
        _isLoadingNotifier.value = false;
      }
      return;
    }

    if (SpUtil.getString('status_idlk') == 'setujui') {
      try {
        var datapulang = {
          'id_user': idUser,
          'id_admin_instansi': idAdmin,
          'ssid': 'IDLK',
          'bssid': 'IDLK',
          'versi': '1.4',
          'deviceId': SpUtil.getString('device_id'),
          'id_type': SpUtil.getString('id_type'),
          'timestamp_pulang': DateTime.now().toIso8601String(),
        };

        http.Response absenPulang = await http.put(
          Uri.parse('$url/api/pulang/$idUser'),
          body: jsonEncode(datapulang),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        final data = jsonDecode(absenPulang.body);

        if (absenPulang.statusCode == 200) {
          code = data['code']?.toString();
          String message = json.encode(data["message"]).replaceAll('"', '');

          if (data["code"] == "1") {
            SpUtil.putString('code_pulang', code!);
            String waktuJson = data['waktu'];
            DateTime waktuText = DateTime.parse(waktuJson);
            jamPulang = DateFormat('HH:mm').format(waktuText);
            SpUtil.putString('pulang', '$jamPulang');

            if (mounted) {
              Alert.alertsuccess(context, message);
              _isCodePulangNotifier.value = true;
              _isPulangCepatNotifier.value = false;
              _isIDLKNotifier.value = false;
              SpUtil.putInt('idlk', 0);
              SpUtil.putString('statusPC', '-');
              SpUtil.putString('status_idlk', '-');
              SpUtil.putBool('is_codePulang', true);
            }
          } else if (data["code"] == "5") {
            if (mounted) {
              Alert.alertinfo(context, message);
              _isCodeMasukNotifier.value = false;
            }
          } else {
            if (mounted) {
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
          Alert.alerterror(context, 'Gagal mengambil absen pulang!');
        }
      } finally {
        if (mounted) {
          _isLoadingNotifier.value = false;
        }
      }
      return;
    }

    if (SpUtil.getString('statusPC') == 'tolak' ||
        SpUtil.getBool('is_codePulang') == false) {
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
                'nama_lengkap': nama,
                'username': SpUtil.getString('username'),
                'instansi': SpUtil.getString('id_instansi'),
                'ssid': connectedSSID,
                'bssid': connectedBSSID,
                'versi': '1.4',
                'deviceId': SpUtil.getString('device_id'),
              };

              http.Response absenPulang = await http.put(
                Uri.parse('$url/api/pulang/$idUser'),
                body: jsonEncode(datapulang),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                },
              ).timeout(const Duration(seconds: 30));

              if (!mounted) return;

              if (absenPulang.statusCode == 200) {
                final data = jsonDecode(absenPulang.body);
                code = data['code']?.toString();
                SpUtil.putString('statusPC', '-');
                SpUtil.putBool('is_PulangCepat', false);
                String message =
                    json.encode(data["message"]).replaceAll('"', '');

                if (data["code"] == "1") {
                  SpUtil.putString('code_pulang', code!);
                  String waktuJson = data['waktu'];
                  DateTime waktuText = DateTime.parse(waktuJson);
                  jamPulang = DateFormat('HH:mm').format(waktuText);
                  SpUtil.putString('pulang', '$jamPulang');
                  SpUtil.putBool('is_codePulang', true);

                  if (mounted) {
                    Alert.alertsuccess(context, message);
                    _isCodePulangNotifier.value = true;
                    _isPulangCepatNotifier.value = false;
                    _isIDLKNotifier.value = false;
                  }
                } else {
                  if (mounted) {
                    Alert.alertwarning(context, message);
                  }
                }
              } else {
                if (mounted) {
                  Alert.alertwarning(
                      context, 'Tidak dapat terhubung ke server');
                }
              }
            } else {
              if (mounted) {
                Alert.alertwarning(
                    context, 'SSID tidak ditemukan dalam daftar WiFi!');
                _isLoadingNotifier.value = false;
              }
            }
          } else {
            if (mounted) {
              Alert.alerterror(context, 'Gagal mengambil absen!');
              _isLoadingNotifier.value = false;
            }
          }
        } catch (e) {
          if (mounted) {
            Alert.alerterror(context, 'Gagal mengambil absen!');
            _isLoadingNotifier.value = false;
          }
        }
      }
    }
  }

  void _checkIdlkandPulangCepat() async {
    try {
      if (SpUtil.getBool('is_IDLK') == true) {
        final response = await http.get(
          Uri.parse('$url/api/cek/idlk/$idUser'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] == 'setujui') {
            SpUtil.putString('status_idlk', 'setujui');
          } else if (data['data'] == 'tolak') {
            SpUtil.putString('status_idlk', 'tolak');
          } else if (data['data'] == 'pending') {
            SpUtil.putString('status_idlk', 'pending');
            SpUtil.putString('statusPC', data['data']);
            SpUtil.putBool('is_codeMasuk', true);
            SpUtil.putBool('is_codePulang', false);
            SpUtil.putBool('is_PulangCepat', false);
            SpUtil.putBool('is_IDLK', true);
            SpUtil.putBool('_isMasuk', true);
            SpUtil.putBool('_isPulang', false);
          }
        } else {
          SpUtil.putString('status_idlk', '-');
          throw Exception('Failed to load data');
        }
      }

      if (SpUtil.getBool('is_PulangCepat') == true) {
        final responsePc = await http.get(
          Uri.parse('$url/api/cek-pulang-cepat/$idUser'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (responsePc.statusCode == 200) {
          final data = jsonDecode(responsePc.body);
          if (data['data'] == 'setujui') {
            SpUtil.putString('statusPC', data['data']);
            SpUtil.putBool('is_codeMasuk', false);
            SpUtil.putBool('is_codePulang', false);
            SpUtil.putBool('is_PulangCepat', false);
            SpUtil.putBool('is_IDLK', false);
            SpUtil.putString('status_idlk', '-');
            SpUtil.putBool('_isMasuk', false);
            SpUtil.putBool('_isPulang', false);

            // Update notifiers
            _isCodeMasukNotifier.value = false;
            _isCodePulangNotifier.value = false;
            _isPulangCepatNotifier.value = false;
            _isIDLKNotifier.value = false;
          } else if (data['data'] == 'tolak') {
            SpUtil.putString('statusPC', data['data']);
            _isPulangCepatNotifier.value = false;
          } else {
            SpUtil.putString('statusPC', 'pending');
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _fetchNotif() async {
    if (idUser == null || idUser!.isEmpty || url == null || url!.isEmpty) {
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
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (responseIzin.statusCode == 200) {
        final data = jsonDecode(responseIzin.body);
        _notifNotifier.value = data["tot_Notif"].toString();
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
    if (!mounted) return;

    _getCurrentTime();
    await _initNetworkInfo();
    await _fetchNotif();
    _isLoadingNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          const Header(), // Assuming Header is a widget

          Column(
            children: [
              SizedBox(height: size.height * 0.15),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: const BorderRadius.only(
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
                  child: Skeletonizer(
                    enabled: _enabled,
                    enableSwitchAnimation: true,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Fitur(),

                        // WiFi Status Widget
                        ValueListenableBuilder<String?>(
                          valueListenable: _wifiNameNotifier,
                          builder: (context, wifiNameValue, child) {
                            final namaSSID =
                                (wifiNameValue?.isNotEmpty ?? false)
                                    ? wifiNameValue!.replaceAll('"', '')
                                    : 'Wifi tidak terhubung';

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 221, 235, 235),
                                ),
                                color: const Color.fromARGB(255, 240, 255, 255),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 226, 226, 226),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Skeleton.replace(
                                        child: Text(
                                          namaSSID.isNotEmpty
                                              ? namaSSID
                                              : 'Wifi tidak terhubung',
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 31, 31),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Time and Date Widget
                        Container(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 5),

                                    // Time Display
                                    ValueListenableBuilder<String>(
                                      valueListenable: _jamSekarangNotifier,
                                      builder: (context, jamValue, child) {
                                        return Text(
                                          jamValue,
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 14, 60, 129),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 5),

                                    // Date Display
                                    Text(
                                      DateFormat('EEEE, dd/MM/yyyy', 'id')
                                          .format(DateTime.now()),
                                      style: const TextStyle(fontSize: 25),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Attendance Buttons
                              ValueListenableBuilder<bool>(
                                valueListenable: _isCodeMasukNotifier,
                                builder: (context, isCodeMasukValue, child) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: _isCodePulangNotifier,
                                    builder:
                                        (context, isCodePulangValue, child) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: _isLoadingNotifier,
                                        builder:
                                            (context, isLoadingValue, child) {
                                          return Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(36.0),
                                                child: Row(
                                                  children: [
                                                    // Check-in Button
                                                    Column(
                                                      children: [
                                                        SpUtil.getBool(
                                                                    'is_codeMasuk') ==
                                                                true
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
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                                    width: 100,
                                                                    height: 100,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      "${SpUtil.getString('masuk')}",
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            30,
                                                                        color: Color.fromARGB(
                                                                            255,
                                                                            2,
                                                                            53,
                                                                            95),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          25),
                                                                ],
                                                              )
                                                            : GestureDetector(
                                                                onTap: isLoadingValue
                                                                    ? null
                                                                    : () async {
                                                                        setState(
                                                                            () {
                                                                          _isMasuk =
                                                                              true;
                                                                        });

                                                                        await _initNetworkInfo();

                                                                        if (_wifiNameNotifier.value != null &&
                                                                            wifiBSSID !=
                                                                                null &&
                                                                            _wifiNameNotifier.value!.isNotEmpty &&
                                                                            wifiBSSID!.isNotEmpty) {
                                                                          Map? _findActiveShiftForAttendance(
                                                                              List shifts,
                                                                              DateTime now) {
                                                                            for (final shift
                                                                                in shifts) {
                                                                              final tglAwal = DateTime.parse(shift['tgl_awal']);
                                                                              final tglAkhir = DateTime.parse(shift['tgl_akhir']);

                                                                              final jamMulaiParts = (shift['jam_mulai'] as String).split(':');
                                                                              final jamSelesaiParts = (shift['jam_selesai'] as String).split(':');

                                                                              final shiftStart = DateTime(
                                                                                tglAwal.year,
                                                                                tglAwal.month,
                                                                                tglAwal.day,
                                                                                int.parse(jamMulaiParts[0]),
                                                                                int.parse(jamMulaiParts[1]),
                                                                              );

                                                                              final shiftEnd = DateTime(
                                                                                tglAkhir.year,
                                                                                tglAkhir.month,
                                                                                tglAkhir.day,
                                                                                int.parse(jamSelesaiParts[0]),
                                                                                int.parse(jamSelesaiParts[1]),
                                                                              );

                                                                              // Toleransi: 5 jam sebelum shift mulai sampai 8 jam setelah shift selesai
                                                                              final startTolerance = shiftStart.subtract(const Duration(hours: 5));
                                                                              final endTolerance = shiftEnd.add(const Duration(hours: 8));

                                                                              if (now.isAfter(startTolerance) && now.isBefore(endTolerance)) {
                                                                                return shift;
                                                                              }
                                                                            }
                                                                            return null;
                                                                          }

                                                                          if (SpUtil.getString('id_type') ==
                                                                              '1') {
                                                                            String?
                                                                                shiftDataString =
                                                                                SpUtil.getString('shift_data');

                                                                            if (shiftDataString != null &&
                                                                                shiftDataString.isNotEmpty) {
                                                                              try {
                                                                                List<dynamic> shifts = jsonDecode(shiftDataString);
                                                                                DateTime now = DateTime.now();

                                                                                // Cari shift yang aktif saat ini
                                                                                Map? activeShift = _findActiveShiftForAttendance(shifts, now);

                                                                                if (activeShift != null) {
                                                                                  // Parse jam shift
                                                                                  final tglAwal = DateTime.parse(activeShift['tgl_awal']);
                                                                                  final tglAkhir = DateTime.parse(activeShift['tgl_akhir']);

                                                                                  final jamMulaiParts = activeShift['jam_mulai'].split(':');
                                                                                  final jamSelesaiParts = activeShift['jam_selesai'].split(':');

                                                                                  final shiftStart = DateTime(
                                                                                    tglAwal.year,
                                                                                    tglAwal.month,
                                                                                    tglAwal.day,
                                                                                    int.parse(jamMulaiParts[0]),
                                                                                    int.parse(jamMulaiParts[1]),
                                                                                  );

                                                                                  final shiftEnd = DateTime(
                                                                                    tglAkhir.year,
                                                                                    tglAkhir.month,
                                                                                    tglAkhir.day,
                                                                                    int.parse(jamSelesaiParts[0]),
                                                                                    int.parse(jamSelesaiParts[1]),
                                                                                  );

                                                                                  // Waktu buka absen: 5 jam sebelum jam mulai
                                                                                  final jamBukaAbsen = shiftStart.subtract(const Duration(hours: 5));

                                                                                  // Cek apakah dalam waktu absen yang diperbolehkan
                                                                                  if (now.isAfter(jamBukaAbsen) && now.isBefore(shiftEnd)) {

                                                                                    await absenMasuk(_wifiNameNotifier.value, wifiBSSID);
                                                                                  } else if (now.isBefore(jamBukaAbsen)) {
                                                                                    // Belum waktunya absen
                                                                                    String jamBukaAbsenStr = DateFormat('HH:mm').format(jamBukaAbsen);
                                                                                    String jamSelesaiStr = DateFormat('HH:mm').format(shiftEnd);

                                                                                    if (mounted) {
                                                                                      Alert.alertwarning(context, 'Waktu absen belum tersedia. Anda bisa absen mulai jam $jamBukaAbsenStr sampai $jamSelesaiStr.');
                                                                                    }
                                                                                    setState(() {
                                                                                      _isMasuk = false;
                                                                                    });
                                                                                  } else {
                                                                                    // Sudah lewat waktu shift, tapi masih dalam periode laporan (8 jam setelah shift)
                                                                                    final reportDeadline = shiftEnd.add(const Duration(hours: 8));

                                                                                    if (now.isBefore(reportDeadline)) {
                                                                                      if (mounted) {
                                                                                        Alert.alertwarning(context, 'Waktu absen sudah berakhir. Anda hanya bisa mengisi laporan harian hingga jam ${DateFormat('HH:mm').format(reportDeadline)}.');
                                                                                      }
                                                                                    } else {
                                                                                      if (mounted) {
                                                                                        Alert.alertwarning(context, 'Waktu absen dan periode laporan sudah berakhir.');
                                                                                      }
                                                                                    }
                                                                                    setState(() {
                                                                                      _isMasuk = false;
                                                                                    });
                                                                                  }
                                                                                } else {
                                                                                  // Tidak ada shift aktif
                                                                                  if (mounted) {
                                                                                    Alert.alertwarning(context, 'Tidak ada shift aktif saat ini. Silakan cek jadwal shift Anda.');
                                                                                  }
                                                                                  setState(() {
                                                                                    _isMasuk = false;
                                                                                  });
                                                                                }
                                                                              } catch (e) {
                                                                                debugPrint('Error parsing shift data: $e');
                                                                                if (mounted) {
                                                                                  Alert.alertwarning(context, 'Terjadi kesalahan saat memproses data shift.');
                                                                                }
                                                                                setState(() {
                                                                                  _isMasuk = false;
                                                                                });
                                                                              }
                                                                            } else {
                                                                              if (mounted) {
                                                                                Alert.alertwarning(context, 'Jam shift tidak ditemukan.');
                                                                              }
                                                                              setState(() {
                                                                                _isMasuk = false;
                                                                              });
                                                                            }
                                                                          } else {
                                                                            await absenMasuk(_wifiNameNotifier.value,
                                                                                wifiBSSID);
                                                                          }
                                                                        } else {
                                                                          if (mounted) {
                                                                            Alert.alertwarning(context,
                                                                                'Silahkan sambungkan ke WiFi!');
                                                                          }
                                                                        }

                                                                        setState(
                                                                            () {
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
                                                                        : Skeletonizer(
                                                                            enabled:
                                                                                _enabled,
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                SizedBox(
                                                                                  width: 100,
                                                                                  child: Skeleton.replace(
                                                                                    child: Image.asset('assets/new/masuk.png'),
                                                                                  ),
                                                                                ),
                                                                                const Text(
                                                                                  "Masuk",
                                                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                                                )
                                                                              ],
                                                                            ),
                                                                          )
                                                                  ],
                                                                ),
                                                              ),
                                                      ],
                                                    ),

                                                    const Spacer(),

                                                    // Check-out Button
                                                    Column(
                                                      children: [
                                                        isCodePulangValue
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
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                                    width: 100,
                                                                    height: 100,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      "${SpUtil.getString('pulang')}",
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              30,
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              2,
                                                                              53,
                                                                              95)),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          25),
                                                                ],
                                                              )
                                                            : GestureDetector(
                                                                onTap: isLoadingValue
                                                                    ? null
                                                                    : () async {
                                                                        setState(
                                                                            () {
                                                                          _isPulang =
                                                                              true;
                                                                        });

                                                                        if (SpUtil.getBool('is_codeMasuk') ==
                                                                                false &&
                                                                            SpUtil.getString('status_idlk') ==
                                                                                '-') {
                                                                          if (mounted) {
                                                                            QuickAlert.show(
                                                                              context: context,
                                                                              type: QuickAlertType.warning,
                                                                              text: "Belum mengambil absen masuk!",
                                                                            );
                                                                          }
                                                                        } else {
                                                                          await _initNetworkInfo();

                                                                          if (SpUtil.getString('status_idlk') ==
                                                                              'setujui') {
                                                                            if (mounted) {
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    title: const Text('Yakin ingin absen pulang Cepat?', style: TextStyle(fontSize: 15)),
                                                                                    actions: <Widget>[
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
                                                                                          await absenPulang('IDLK', 'IDLK');
                                                                                        },
                                                                                      ),
                                                                                      TextButton(
                                                                                        style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge, backgroundColor: Colors.red),
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
                                                                            }
                                                                          } else if (_wifiNameNotifier.value != null &&
                                                                              wifiBSSID != null &&
                                                                              _wifiNameNotifier.value!.isNotEmpty &&
                                                                              wifiBSSID!.isNotEmpty) {
                                                                            if (mounted) {
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    title: const Text('Yakin ingin absen pulang?', style: TextStyle(fontSize: 15)),
                                                                                    actions: <Widget>[
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
                                                                                          await absenPulang(_wifiNameNotifier.value, wifiBSSID);
                                                                                        },
                                                                                      ),
                                                                                      TextButton(
                                                                                        style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge, backgroundColor: Colors.red),
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
                                                                            }
                                                                          } else {
                                                                            if (mounted) {
                                                                              Alert.alertwarning(context, 'Silahkan sambungkan ke Wifi!');
                                                                            }
                                                                          }
                                                                        }

                                                                        setState(
                                                                            () {
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
                                                                        : Skeletonizer(
                                                                            enabled:
                                                                                _enabled,
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                SizedBox(
                                                                                  width: 100,
                                                                                  child: Skeleton.replace(
                                                                                    child: Image.asset('assets/new/pulang.png'),
                                                                                  ),
                                                                                ),
                                                                                if (SpUtil.getString('status_idlk') != 'setujui')
                                                                                  const Text(
                                                                                    "Pulang",
                                                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                                                  )
                                                                                else
                                                                                  const Text(
                                                                                    "IDLK",
                                                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                                                  )
                                                                              ],
                                                                            ),
                                                                          )
                                                                  ],
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),

                              // Conditional Widgets
                              ValueListenableBuilder<bool>(
                                valueListenable: _isPulangCepatNotifier,
                                builder: (context, isPulangCepatValue, child) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: _isIDLKNotifier,
                                    builder: (context, isIDLKValue, child) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: _isCodeMasukNotifier,
                                        builder:
                                            (context, isCodeMasukValue, child) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                _isCodePulangNotifier,
                                            builder: (context,
                                                isCodePulangValue, child) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  _buildConditionalWidgets(
                                                    context,
                                                    isPulangCepatValue,
                                                    isIDLKValue,
                                                    isCodeMasukValue,
                                                    isCodePulangValue,
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionalWidgets(
    BuildContext context,
    bool isPulangCepat,
    bool isIDLK,
    bool isCodeMasuk,
    bool isCodePulang,
  ) {
    final statusPC = SpUtil.getString('statusPC');

    if (isPulangCepat || isIDLK) {
      if (SpUtil.getString('status_idlk') == 'setujui') {
        return Card(
          color: Colors.green,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'IDLK sudah di setujui \nsilahkan mengambil absen pulang',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(initialIndex: 3),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 173, 218, 255),
          ),
          child: const Text(
            'Status Pengajuan',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 162, 255),
            ),
          ),
        );
      }
    } else if (statusPC == 'setujui') {
      return const Card(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Pulang Cepat sudah di setujui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } else if (statusPC == 'tolak') {
      return const Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Pulang Cepat ditolak \n Tetap gunakan absen pulang!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } else if (isCodeMasuk && !isCodePulang) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PulangCepat(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Pulang Cepat',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
