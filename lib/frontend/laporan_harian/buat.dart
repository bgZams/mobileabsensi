import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final Color primaryBlue = const Color(0xFF1565C0);
    final Color lightBlueBg = const Color(0xFFE3F2FD);
    return Scaffold(
      body: Stack(
        children: [
          WidgetNavbar(title: 'Buat Laporan Harian'),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),

                                // === BARIS INPUT JAM (RESPONSIF) ===
                                Row(
                                  children: [
                                    // 1. JAM MULAI
                                    Expanded(
                                      child: TextFormField(
                                        controller: jamMulai,
                                        readOnly: true,
                                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                        decoration: _inputDecoration(
                                          label: "Jam Mulai",
                                          icon: Icons.timer,
                                          bgColor: lightBlueBg,
                                          primaryColor: primaryBlue,
                                        ),
                                        onTap: () async {
                                          // Logika Asli Anda (SpUtil)
                                          if (SpUtil.getString('masuk')!.isNotEmpty) {
                                            setState(() {
                                              jamMulai.text = SpUtil.getString('masuk').toString();
                                            });
                                          } else {
                                            TimeOfDay? pickedTime = await showTimePicker(
                                              initialTime: TimeOfDay.now(),
                                              context: context,
                                            );
                                            if (pickedTime != null) {
                                              String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                              setState(() {
                                                jamMulai.text = formattedTime;
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 15), // Jarak antar kolom

                                    Expanded(
                                      child: TextFormField(
                                        controller: jamSelesai,
                                        readOnly: true,
                                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                        decoration: _inputDecoration(
                                          label: "Jam Selesai",
                                          icon: Icons.timer,
                                          bgColor: lightBlueBg,
                                          primaryColor: primaryBlue,
                                        ),
                                        onTap: () async {
                                          TimeOfDay? pickedTime = await showTimePicker(
                                            initialTime: TimeOfDay.now(),
                                            context: context,
                                          );
                                          if (pickedTime != null) {
                                            String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                            setState(() {
                                              jamSelesai.text = formattedTime;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 25),

                                TextFormField(
                                  controller: keterangan,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      Alert.alerterror(context, 'Keterangan tidak boleh kosong');
                                      return 'Wajib diisi';
                                    }
                                    return null;
                                  },
                                  maxLines: 5,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: "Deskripsi Kegiatan",
                                    alignLabelWithHint: true,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(bottom: 80), // Icon di atas
                                      child: Icon(Icons.description_outlined, color: primaryBlue),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white, // Background putih bersih
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: primaryBlue, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _startLoading,
                                    icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, color: Colors.white),
                                    label: Text(
                                      isLoading ? 'Menyimpan...' : 'SIMPAN DATA',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue, // Menggunakan variabel warna biru
                                      elevation: 4,
                                      shadowColor: primaryBlue.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: const Color.fromARGB(255, 255, 204, 51),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Info',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text('1. Jam mulai sesuaikan dengan jam absen masuk'),
                                  Text('2. Jam mulai tidak lebih besar dari jam selesai'),
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
    if (idPimpinan == null) {
      Alert.alertwarning(context, 'ID Atasan tidak ditemukan');
    }
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

    if (idServer == null || idUser == null || idPimpinan == null || idAdmin == null) {
      // ignore: use_build_context_synchronously
      Alert.alertinfo(context, 'Data pengguna tidak lengkap!');

      return;
    }

    if (mulai.isEmpty || selesai.isEmpty || SpUtil.getString('masuk')!.isEmpty) {
      Alert.alerterror(context, 'Jam tidak boleh kosong');
      return;
    }
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
        final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
        databaseReference.child("laporan").push().set(storeFirebase);
        prosesResponSukses(kirimLaporanHarian.body);
      } else {
        Map<String, dynamic> errorResponse = jsonDecode(kirimLaporanHarian.body);
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
      Alert.alerterror(context, 'Terjadi Kesalahan, Silahkan coba lagi!');
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
