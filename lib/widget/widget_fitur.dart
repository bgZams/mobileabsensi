import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobileabsensi/frontend/apel.dart';
import 'package:mobileabsensi/frontend/izin/konfirmasi_izin.dart';
import 'package:mobileabsensi/frontend/list_wifi.dart';
import 'package:mobileabsensi/frontend/statistik.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class Fitur extends StatefulWidget {
  const Fitur({super.key});

  @override
  State<Fitur> createState() => _FiturState();
}

class _FiturState extends State<Fitur> {
  final StreamController<String> _jlhIzinController = StreamController<String>.broadcast();
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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          nama = SpUtil.getString("nama_lengkap");
          instansi = SpUtil.getString("nama_instansi");
        });
      }
    });
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
      bool isLoading = false;

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
      child: Skeletonizer(
        enabled: isLoading,
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
                      icon:   Icon(Icons.grid_view_rounded, color: Colors.white,),
                      onPressed: () async {
                            _showGridMenu(context);
                      }
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  const Text(
                    'Lain',
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
      ),
    );
  }

   // Fungsi untuk menampilkan menu Grid
  void _showGridMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Data untuk menu, agar kode lebih rapi
        final List<Map<String, dynamic>> menuItems = [
          {'icon': Icons.access_time_sharp, 'label': 'Shift', 'value': 'fitur_1'},
          {'icon': Icons.calendar_today_outlined, 'label': 'Libur', 'value': 'fitur_2'},
        ];

        return Dialog(
          // Menghapus shape default agar bisa full width
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              // Membuat lebar dialog mengikuti lebar layar dengan sedikit margin
              width: MediaQuery.of(context).size.width,
              height: 250,
              child: Column(
                children: [
                  Text(
                'Menu Lainnya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Container(

                margin: const EdgeInsets.symmetric(vertical: 8.0),
                height: 2.0,
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).primaryColor,
              ),
                  GridView.builder(
                    // Agar grid tidak menyebabkan dialog membesar tak terbatas
                    shrinkWrap: true,
                    // Jumlah item per baris
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( // Diperbaiki: Gunakan properti gridDelegate
                      crossAxisCount: 4,
                      // Jarak antar item secara horizontal
                      crossAxisSpacing: 16.0,
                      // Jarak antar item secara vertikal
                      mainAxisSpacing: 16.0,
                    ),
                    // Total item yang akan dibangun
                    itemCount: menuItems.length,
                    // Mencegah grid dari scrollable jika item sedikit
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final item = menuItems[index];
                      return InkWell(
                        onTap: () {
                          // Tutup dialog
                          Navigator.of(context).pop();
                          // Eksekusi aksi berdasarkan nilai
                          _handleMenuSelection(item['value']);
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'],
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['label'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                            
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk menangani seleksi menu
  void _handleMenuSelection(String? value) {
    if (value == null) return;

    // Gunakan print untuk contoh.

    switch (value) {
      case 'fitur_1':
        Navigator.pushNamed(context, '/shift');
        break;
      case 'fitur_2':
        Fluttertoast.showToast(
          msg: "Fitur Libur belum tersedia",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0
        );
        break;
    }
  }
}
