import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/absen/pulang_cepat.dart';
import 'package:mobileabsensi/frontend/blog.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/navigasi.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sp_util/sp_util.dart';

class Absen extends StatefulWidget {
  const Absen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AbsenState createState() => _AbsenState();
}

class _AbsenState extends State<Absen> {
  final StreamController<String> _jlhIzinController =
      StreamController<String>();
  Timer? _timer;
  var url = SpUtil.getString("url");
  String _jamSekarang = '';
  List<Map<String, dynamic>> wifiData = [];
  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isLoading = false;
  bool _isMasuk = false;
  bool _isPulang = false;

  String? wifiName = '';
  String? wifiBSSID = '';
  // String? wifiName = 'SEKRETARIAT KOMINFO';
  // String? wifiBSSID = 'e0:63:da:a1:9d:6b';
  String? wifiIPv4;

  String? masuk = '';
  String? formattedDate;
  String? jamMasuk;
  String? jamPulang;
  String? code;
  bool isCodeMasuk = false;
  bool isCodePulang = false;
  bool isPulangCepat = false;
  var idUser = SpUtil.getString("id_user");
  var idAdmin = SpUtil.getString("id_admin_instansi");
  var admin = SpUtil.getString("username_admin");
  String jlh_izin = '';
  String? notif = '';

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    _jamSekarang = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getCurrentTime());
    loadWifiData();
    isCodeMasuk = SpUtil.getBool('is_codeMasuk') ?? false;
    isCodePulang = SpUtil.getBool('is_codePulang') ?? false;
    isPulangCepat = SpUtil.getBool('is_PulangCepat') ?? false;
    _jlhIzinController.add(SpUtil.getInt("jlh_izin").toString());
    _simulateDataUpdate();
    _fetchNotif();
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

  String _tglSekarang(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  Future<void> loadWifiData() async {
    String wifiDataJson = SpUtil.getString("wifi_data") ?? '[]';

    if (wifiDataJson.isNotEmpty) {
      List<dynamic> decodedData = json.decode(wifiDataJson);
      wifiData = List<Map<String, dynamic>>.from(decodedData);
    }

    setState(() {});
  }

  Future<void> _initNetworkInfo() async {
    try {
      wifiName = await _networkInfo.getWifiName();
      wifiBSSID = await _networkInfo.getWifiBSSID();
      wifiIPv4 = await _networkInfo.getWifiIP();
      // Check if wifiName is null
      wifiName ??= 'Not connected to Wi-Fi';
    } on PlatformException catch (e) {
      developer.log('Failed to get Wi-Fi Name or BSSID', error: e);
      wifiName = 'Failed to get Wi-Fi Name';
      wifiBSSID = 'Failed to get Wi-Fi BSSID';
    }
  }

  Future<void> absenMasuk(String? wifiName, String? wifiBSSID) async {
    // Future<void> absenMasuk() async {
    String connectedSSID = wifiName ?? '';
    String ssID = connectedSSID.replaceAll('"', '');
    String connectedBSSID = wifiBSSID ?? '';

    if (SpUtil.getString("id_user") != null) {
      try {
        print('$url/api/masuk');
        var datamasuk = {
          'id_user': idUser,
          'id_admin_instansi': idAdmin,
          'ssid': ssID,
          'bssid': connectedBSSID,
          'versi': '1.4'
        };
        http.Response absenMasuk = await http.post(
          Uri.parse('$url/api/masuk'),
          body: datamasuk,
        );
        if (absenMasuk.statusCode == 200) {
          final data = jsonDecode(absenMasuk.body);

          String message = json.encode(data["message"]).replaceAll('"', '');
          if (data["code"] == "wifi") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "versi_app") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "unknown") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "1") {
            code = data['code']?.toString();
            SpUtil.putString('code_masuk', code!);
            String message = json.encode(data['message']);
            SpUtil.putString('message', message.replaceAll('"', ''));
            String waktuJson = data['waktu'];
            DateTime waktuText = DateTime.parse(waktuJson);
            jamMasuk = DateFormat('HH:mm').format(waktuText);
            SpUtil.putString('masuk', '$jamMasuk');
            SpUtil.putBool('is_codeMasuk', true);
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: message,
            );
            setState(() {
              isCodeMasuk = true;
            });
          } else if (data["code"] == "2") {
            code = data['code']?.toString();
            SpUtil.putString('code_masuk', code!);
            String message = json.encode(data['message']);
            SpUtil.putString('message', message.replaceAll('"', ''));
            String waktuJson = data['waktu'];
            DateTime waktuText = DateTime.parse(waktuJson);
            jamMasuk = DateFormat('HH:mm').format(waktuText);
            SpUtil.putString('masuk', '$jamMasuk');
            SpUtil.putBool('is_codeMasuk', true);
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.info,
              text: message,
            );
            setState(() {
              isCodeMasuk = true;
            });
          }
        } else {
          throw Exception('Kesalahan HTTP: ${absenMasuk.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> absenPulang(String? wifiName, String? wifiBSSID) async {
    // Future<void> absenPulang() async {
    String connectedSSID = wifiName ?? '';
    String ssID = connectedSSID.replaceAll('"', '');
    String connectedBSSID = wifiBSSID ?? '';
    if (SpUtil.getString("id_user") != null) {
      try {
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
          final data = jsonDecode(absenPulang.body);

          code = data['code']?.toString();
          String message = json.encode(data["message"]).replaceAll('"', '');
          if (data["code"] == "wifi") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "versi_app") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "unknown") {
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: message,
            );
          } else if (data["code"] == "1") {
            SpUtil.putString('code_pulang', code!);
            SpUtil.putString('message', message.replaceAll('"', ''));
            String waktuJson = data['waktu'];
            DateTime waktuText = DateTime.parse(waktuJson);
            jamPulang = DateFormat('HH:mm').format(waktuText);
            SpUtil.putString('pulang', '$jamPulang');
            SpUtil.putBool('is_codePulang', true);
            // ignore: use_build_context_synchronously
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: message,
            );
            setState(() {
              isCodePulang = true;
            });
          }
        } else {
          throw Exception('Kesalahan HTTP: ${absenPulang.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error: $e');
        }
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
        setState(() {
          final data = jsonDecode(responseIzin.body);
          notif = data["tot_Notif"].toString();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _getCurrentTime();
      _initNetworkInfo();
      _fetchNotif();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // loadWifiData();
          // _refreshData();
        },
        child: SizedBox(
          height: deviceHeight * 1.2,
          child: Container(
            color: const Color.fromARGB(255, 238, 238, 238),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Stack(
                children: [
                  // Background Image
                  Container(
                    height: size.height * .3,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: AssetImage('assets/images/imgheader.png'),
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
                                // Header with Profile and Logout Button
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
                                      const SizedBox(width: 1),
                                      SizedBox(
                                        width: 180,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${SpUtil.getString("nama_lengkap") ?? ''}",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                                "${SpUtil.getString("nama_instansi") ?? ''}",
                                                style: TextStyle(fontSize: 12)),
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
                                                  const Icon(
                                                      Icons.notifications),
                                                  if (snapshot.hasData &&
                                                      snapshot.data != null)
                                                    Positioned(
                                                      right: 28,
                                                      top: 0,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(1),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        constraints:
                                                            const BoxConstraints(
                                                          minWidth: 18,
                                                          minHeight: 18,
                                                        ),
                                                        child: Text(
                                                          notif!,
                                                          style:
                                                              const TextStyle(
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
                                      SizedBox(
                                        width: 10,
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color.fromARGB(
                                              255, 14, 60, 129),
                                          width: 3),
                                      color: Color.fromARGB(255, 1, 74, 184),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                color: const Color.fromARGB(
                                                    255, 14, 60, 129),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              child: IconButton(
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.envelope,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {},
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            const Text(
                                              'Pesan',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                color: const Color.fromARGB(
                                                    255, 14, 60, 129),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              child: IconButton(
                                                icon: const FaIcon(
                                                  FontAwesomeIcons
                                                      .usersBetweenLines,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Apel()),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            const Text(
                                              'Apel',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                color: const Color.fromARGB(
                                                    255, 14, 60, 129),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.wifi,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const ListWifi()),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            const Text(
                                              'Wifi',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                color: const Color.fromARGB(
                                                    255, 14, 60, 129),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              child: IconButton(
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.bullhorn,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Pengumuman()),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            const Text(
                                              'Info',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                color: const Color.fromARGB(
                                                    255, 14, 60, 129),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(10)),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.newspaper,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Blog()),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            const Text(
                                              'Blog',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                              '$wifiName',
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
                                            borderRadius:
                                                const BorderRadius.all(
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
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
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
                                      // Wi-Fi Name Display
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 20),
                                          // Absent Buttons
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 40),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    // Check-in Button
                                                    isCodeMasuk
                                                        ? Container(
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
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        30,
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            2,
                                                                            53,
                                                                            95))),
                                                          )
                                                        : GestureDetector(
                                                            onTap: () async {
                                                              setState(() {
                                                                _isMasuk = true;
                                                              });

                                                              await _initNetworkInfo();

                                                              if (wifiName != null &&
                                                                  wifiBSSID !=
                                                                      null &&
                                                                  wifiName!
                                                                      .isNotEmpty &&
                                                                  wifiBSSID!
                                                                      .isNotEmpty) {
                                                                await absenMasuk(
                                                                    wifiName,
                                                                    wifiBSSID);
                                                                // await absenMasuk(
                                                                //     wifiName,
                                                                //     wifiBSSID);
                                                              } else {
                                                                // developer.log(
                                                                //     'Tidak Ada Informasi Wi-Fi yang Tersedia',
                                                                //     level: 0);
                                                                //ignore: use_build_context_synchronously
                                                                QuickAlert.show(
                                                                  context:
                                                                      context,
                                                                  type: QuickAlertType
                                                                      .warning,
                                                                  text:
                                                                      "Tidak Ada Informasi Wi-Fi yang Tersedia",
                                                                );
                                                              }
                                                              // await absenMasuk();

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
                                                                            child:
                                                                                Image.asset('assets/images/sidikjari1new.png'),
                                                                          ),
                                                                          const Text(
                                                                            "Masuk",
                                                                            style:
                                                                                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                                    // Check-out Button
                                                    isCodePulang
                                                        ? Container(
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
                                                          )
                                                        : GestureDetector(
                                                            onTap: () async {
                                                              setState(() {
                                                                _isPulang =
                                                                    true;
                                                              });

                                                              if (isCodeMasuk ==
                                                                  false) {
                                                                // developer.log(
                                                                //     'Belum mengambil absen masuk',
                                                                //     level: 0);
                                                                QuickAlert.show(
                                                                  context:
                                                                      context,
                                                                  type: QuickAlertType
                                                                      .warning,
                                                                  text:
                                                                      "Belum mengambil absen masuk!",
                                                                );
                                                              } else {
                                                                await _initNetworkInfo();
                                                                if (wifiName !=
                                                                        null &&
                                                                    wifiBSSID !=
                                                                        null &&
                                                                    wifiName!
                                                                        .isNotEmpty &&
                                                                    wifiBSSID!
                                                                        .isNotEmpty) {
                                                                  absenPulang(
                                                                      wifiName,
                                                                      wifiBSSID);
                                                                } else {
                                                                  // developer.log(
                                                                  //     'Tidak Ada Informasi Wi-Fi yang Tersedia',
                                                                  //     level: 0);
                                                                  // ignore: use_build_context_synchronously
                                                                  QuickAlert
                                                                      .show(
                                                                    context:
                                                                        context,
                                                                    type: QuickAlertType
                                                                        .error,
                                                                    text:
                                                                        "Tidak Ada Informasi Wi-Fi yang Tersedia",
                                                                  );
                                                                }
                                                                // absenPulang();
                                                              }

                                                              setState(() {
                                                                _isPulang =
                                                                    false; // Set isLoading back to false after operation is completed
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
                                                                            child:
                                                                                Image.asset('assets/images/sidikjari2new.png'),
                                                                          ),
                                                                          const Text(
                                                                            "Pulang",
                                                                            style:
                                                                                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                                          )
                                                                        ],
                                                                      ),
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
                                            isCodeMasuk == true
                                                ? isPulangCepat == true
                                                    ? Center(
                                                        child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const RiwayatIzin()),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          primary: const Color
                                                              .fromARGB(
                                                              255,
                                                              173,
                                                              218,
                                                              255), // Mengatur warna latar belakang menjadi merah
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
                                                      ))
                                                    : Center(
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const PulangCepat()),
                                                              );
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              primary: Colors
                                                                  .red, // Mengatur warna latar belakang menjadi merah
                                                            ),
                                                            child: const Text(
                                                              'Pulang Cepat',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white), // Mengatur warna teks menjadi putih
                                                            )))
                                                : Container()
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
