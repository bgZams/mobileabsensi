import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class EditLaporan extends StatefulWidget {
  const EditLaporan({Key? key}) : super(key: key);

  @override
  State<EditLaporan> createState() => _EditLaporanState();
}

class _EditLaporanState extends State<EditLaporan> {
  var url = SpUtil.getString("url");
  TextEditingController jamMulai = TextEditingController();
  TextEditingController jamSelesai = TextEditingController();
  TextEditingController keterangan = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  void _startLoading() async {
    setState(() {
      _isLoading = true; // Menampilkan loader sebelum memulai pengiriman data
    });

    if (_formKey.currentState!.validate()) {
      try {
        await kirimLaporan(); // Memanggil fungsi pengiriman data
      } catch (error) {
        if (kDebugMode) {
          print("Error: $error");
        }
      } finally {
        setState(() {
          _isLoading = false; // Menutup loader setelah proses selesai
        });
      }
    } else {
      setState(() {
        _isLoading = false; // Menutup loader jika validasi gagal
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: jamMulai,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.timer),
                        labelText: "Jam Mulai",
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          initialTime: TimeOfDay.now(),
                          context: context,
                        );

                        if (pickedTime != null) {
                          String formattedTime =
                              "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}";
                          setState(() {
                            jamMulai.text = formattedTime;
                          });
                        } else {
                          // if (kDebugMode) {
                          //   print("Time is not selected");
                          // }
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: jamSelesai,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.timer),
                        labelText: "Jam Selesai",
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          initialTime: TimeOfDay.now(),
                          context: context,
                        );

                        if (pickedTime != null) {
                          String formattedTime =
                              "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}";
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.black45,
                  child: TextFormField(
                    controller: keterangan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kegiatan tidak boleh kosong';
                      }
                      return null;
                    },
                    maxLines: 10,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Masukkan kegiatan",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      fillColor: Colors.black45,
                      filled: true,
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading ? 'Loading...' : 'Simpan',
                  style: const TextStyle(fontSize: 14),
                ),
                onPressed: _isLoading ? null : _startLoading,
                style: ElevatedButton.styleFrom(fixedSize: const Size(140, 40)),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
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
    var now = DateFormat('yyyy-mm-dd').format(DateTime.now());

    Map<String, dynamic> data = {
      'id_user': idUser,
      'id_atasan': idPimpinan,
      'jammulai': mulai,
      'jamselesai': selesai,
      'rincian_kegiatan': kegiatan,
      'id_status':0,
    };
    Map<String, dynamic> storeFirebase = {
      'tanggal': now,
      'id_user': idUser,
      'id_atasan': idPimpinan,
      'id_status': 0, 
      'nama_lengkap': namalengkap,
      'jenis_izin': 'laporan harian',
      'key_notif': 'laporan'
    };

    if (idServer == null ||
        idUser == null ||
        idPimpinan == null ||
        idAdmin == null) {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        text: 'Data pengguna tidak lengkap',
      );
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
      // print(kirimLaporanHarian.statusCode);

      if (kirimLaporanHarian.statusCode == 200) {
        final DatabaseReference databaseReference =
            FirebaseDatabase.instance.ref();
        databaseReference.child("laporan").push().set(storeFirebase);
        prosesResponSukses(kirimLaporanHarian.body);
      } else {
        // ignore: use_build_context_synchronously
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Terjadi kesalahan server',
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Terjadi kesalahan jaringan',
      );
    }
  }

  void prosesResponSukses(String responseBody) {
    final responseData = jsonDecode(responseBody);
    String message = responseData["message"].toString();

    if (responseData['status'] == false) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: message,
      );
    } else {
      
      bersihkanForm();
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: message,
      );
    }
  }

  void bersihkanForm() {
    jamMulai.clear();
    jamSelesai.clear();
    keterangan.clear();
  }
}
