import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class BuatLaporan extends StatefulWidget {
  const BuatLaporan({super.key});

  @override
  State<BuatLaporan> createState() => _BuatLaporanState();
}

class _BuatLaporanState extends State<BuatLaporan> {
  var url = SpUtil.getString("url");
  TextEditingController jamMulai = TextEditingController();
  TextEditingController jamSelesai = TextEditingController();
  TextEditingController keterangan = TextEditingController();
  bool laporanPertama = false;
  bool laporanKedua = true;

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  void _startLoading() async {
    setState(() {
      isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        await kirimLaporan();
      } catch (error) {
        if (kDebugMode) {
          print("Error: $error");
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    jamMulai.dispose();
    jamSelesai.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      laporanPertama = SpUtil.getBool('laporanPertama') ?? false;
      laporanKedua = SpUtil.getBool('laporanKedua') ?? false;
    });
    if (laporanPertama == false && laporanKedua == false) {
      jamMulai.text = SpUtil.getString('masuk').toString();
    } else {
      jamMulai.text = SpUtil.getString('mulai').toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Header().header(context),
          // Scrollable content area taking most of the screen
          Column(
            children: [
              // Spacer to push content down to create overlap
              SizedBox(height: size.height * 0.15),

              // Content area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Column(
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Buat Laporan Harian',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 50, 50, 50),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: TextField(
                                        // enabled: laporanPertama,
                                        controller: jamMulai,
                                        decoration: const InputDecoration(
                                          labelText: "Jam Mulai",
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          if (SpUtil.getString('masuk')!
                                              .isEmpty) {
                                            setState(() {
                                              jamMulai.text =
                                                  SpUtil.getString('masuk')
                                                      .toString();
                                            });
                                          } else {
                                            TimeOfDay? pickedTime =
                                                await showTimePicker(
                                              initialTime: TimeOfDay.now(),
                                              context: context,
                                            );
                                            if (pickedTime != null) {
                                              String formattedTime =
                                                  "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                              setState(() {
                                                jamMulai.text = formattedTime;
                                              });
                                            } else {
                                              // Time is not selected
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    Spacer(),
                                    SizedBox(
                                      width: 150,
                                      child: TextField(
                                        controller: jamSelesai,
                                        decoration: const InputDecoration(
                                          labelText: "Jam Selesai",
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          TimeOfDay? pickedTime =
                                              await showTimePicker(
                                            initialTime: TimeOfDay.now(),
                                            context: context,
                                          );

                                          if (pickedTime != null) {
                                            String formattedTime =
                                                "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                            setState(() {
                                              jamSelesai.text = formattedTime;
                                            });
                                          } else {
                                            if (kDebugMode) {
                                              print("Time is not selected");
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Container(
                                  color: Colors.black45,
                                  child: TextFormField(
                                    controller: keterangan,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        Alert.alerterror(context,
                                            'Keterangan tidak boleh kosong');
                                      }
                                      return null;
                                    },
                                    maxLines: 10,
                                    style:
                                        const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                                    decoration: const InputDecoration(
                                      labelText: "Masukkan kegiatan",
                                      alignLabelWithHint: true,
                                      labelStyle:
                                          TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                                      border: OutlineInputBorder(),
                                      fillColor: Color.fromARGB(115, 245, 243, 243),
                                      filled: true,
                                      errorStyle:
                                          TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: ElevatedButton.icon(
                                    icon: isLoading
                                        ? const CircularProgressIndicator()
                                        : const Icon(
                                            Icons.save_outlined,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      isLoading ? 'Loading...' : 'Simpan',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                                offset: Offset(1, 1))
                                          ]),
                                    ),
                                    onPressed:
                                        isLoading ? null : _startLoading,
                                    clipBehavior: Clip.hardEdge,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5))),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color:
                                    const Color.fromARGB(255, 255, 204, 51),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Info',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                      '1. Jam mulai sesuaikan dengan jam absen masuk'),
                                  Text(
                                      '2. Jam mulai tidak lebih besar dari jam selesai'),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      // Add more content elements here
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  kirimLaporan() async {
    String mulai = jamMulai.text;
    String selesai = jamSelesai.text;
    String kegiatan = keterangan.text;
    String? idServer = SpUtil.getString('id_server');
    String? idUser = SpUtil.getString('id_user');
    String? idPimpinan = SpUtil.getString('id_user_pimpinan');
    String? idAdmin = SpUtil.getString('id_admin_instansi');
    String namalengkap = SpUtil.getString("nama_lengkap").toString();
    var now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, dynamic> data = {
      'id_user': idUser,
      'id_atasan': idPimpinan,
      'jammulai': mulai,
      'jamselesai': selesai,
      'rincian_kegiatan': kegiatan,
      'id_status': 0,
    };

    Map<String, dynamic> storeFirebase = {
      'tanggal': now,
      'id_user': idUser,
      'id_atasan': idPimpinan,
      'id_status': 0,
      'nama_lengkap': namalengkap,
      'jenis_izin': 'laporan harian',
      'key_notif': 'laporan',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (idServer == null ||
        idUser == null ||
        idPimpinan == null ||
        idAdmin == null) {
      // ignore: use_build_context_synchronously
      Alert.alertinfo(context, 'Data pengguna tidak lengkap!');

      return;
    }

    if (mulai.isEmpty ||
        selesai.isEmpty ||
        SpUtil.getString('masuk')!.isEmpty) {
      Alert.alerterror(context, 'Jam tidak boleh kosong');
      return;
    }

    // DateTime jamMulaiTime = DateFormat("HH:mm").parse(mulai);
    // // DateTime jamSelesaiTime = DateFormat("HH:mm").parse(selesai);
    // DateTime jamMasukTime = DateFormat("HH:mm").parse(SpUtil.getString('masuk').toString());
    // // DateTime jamPulangTime = DateFormat("HH:mm").parse(SpUtil.getString('pulang').toString());

    // if (jamMulaiTime.isBefore(jamMasukTime)) {
    //   Alert.alerterror(
    //       context, 'Jam mulai tidak boleh lebih kecil dari jam masuk');
    //   return;
    // }
    // if (jamSelesaiTime.isAfter(jamPulangTime)) {
    //   Alert.alerterror(
    //       context, 'Jam selesai tidak boleh lebih besar dari jam pulang');
    //   return;
    // }
    try {
      http.Response kirimLaporanHarian = await http.post(
        Uri.parse('$url/api/simpan-lhk'),
        body: jsonEncode(data),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (kirimLaporanHarian.statusCode == 200) {
        final DatabaseReference databaseReference =
            FirebaseDatabase.instance.ref();
        databaseReference.child("laporan").push().set(storeFirebase);
        prosesResponSukses(kirimLaporanHarian.body);
      } else {
        Map<String, dynamic> errorResponse =
            jsonDecode(kirimLaporanHarian.body);
        String errorMessage = 'Terjadi kesalahan server';
        if (errorResponse.containsKey('errors')) {
          Map<String, dynamic> errors = errorResponse['errors'];
          if (errors.containsKey('jamselesai')) {
            errorMessage = errors['jamselesai'].join(', ');
          }
        }

        // ignore: use_build_context_synchronously
        Alert.alerterror(context, errorMessage);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Alert.alerterror(context, 'Terjadi Kesalahan Jaringan!');
    }
  }

  void prosesResponSukses(String responseBody) {
    final responseData = jsonDecode(responseBody);

    if (responseData['status'] == 'success') {
      // bersihkanForm();
      SpUtil.putString('mulai', jamSelesai.text);
      Navigator.pop(context, true);
      Alert.alertsuccess(context, 'Laporan harian berhasil disimpan');
    } else {
      Alert.alerterror(context, 'Gagal membuat laporan harian');
    }
  }

  void bersihkanForm() {
    jamMulai.clear();
    jamSelesai.clear();
    keterangan.clear();
  }
}
