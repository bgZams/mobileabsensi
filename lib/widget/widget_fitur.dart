import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/pengumuman.dart';
import 'package:mobileabsensi/frontend/statistik.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class Fitur extends StatefulWidget {
  const Fitur({super.key});

  @override
  State<Fitur> createState() => _FiturState();
}

class _FiturState extends State<Fitur> {
  final StreamController<String> _jlhIzinController = StreamController<String>();
  String? notif = '0';
  String? idUser = SpUtil.getString("id_user");
  String? idAdmin = SpUtil.getString("id_admin_instansi") ?? '';
  String? admin = SpUtil.getString("username_admin") ?? '';
  String? nama = SpUtil.getString("nama_lengkap").toString();
  String? instansi = SpUtil.getString("nama_instansi").toString();
  String? url = SpUtil.getString("url");

  @override
  void initState() {
    super.initState();
    _jlhIzinController.add(SpUtil.getInt("jlh_izin").toString());
    fetchNotif();
  }

  @override
  void dispose() {
    _jlhIzinController.close();
    super.dispose();
  }

  Future<void> fetchNotif() async {
    try {
      final responseIzin = await http.get(
        Uri.parse('$url/api/notif/get-notif-count/$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (responseIzin.statusCode == 200) {
        final data = jsonDecode(responseIzin.body);
        notif = data["tot_Notif"].toString();
        _jlhIzinController.add(notif!);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return fiturMenu(context);
  }

  Widget fiturMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
        top: 10,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(
                                    color: const Color.fromARGB(255, 221, 235, 235),width: 3),
        color: const Color.fromARGB(255, 240, 255, 255),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StreamBuilder<String>(
              stream: _jlhIzinController.stream,
              builder: (context, snapshot) {
                return Column(
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        color: const Color.fromARGB(255, 67, 60, 130),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.mail_outline_sharp,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KonfirmasiIzin(),
                                ),
                              );
                            }
                          ),
                          if (snapshot.hasData && snapshot.data != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    notif ?? '0',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    const Text(
                      'Pesan',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                );
              },
            ),
            
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 67, 60, 130),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.usersBetweenLines,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Apel()),
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
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 67, 60, 130),
                    borderRadius: const BorderRadius.all(
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
                            builder: (context) => const ListWifi()),
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
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color.fromARGB(255, 67, 60, 130),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Statistik()),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    color: const Color.fromARGB(255, 67, 60, 130),
                    borderRadius: const BorderRadius.all(
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
                            builder: (context) => const Pengumuman()),
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
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }
}
