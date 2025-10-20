import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core/constants/app_constants.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/main.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'dart:convert';

import 'package:sp_util/sp_util.dart';

class EditLaporan extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpdate; // Callback function
  

  const EditLaporan({super.key, required this.data, required this.onUpdate});

  @override
  EditLaporanState createState() => EditLaporanState();
}

class EditLaporanState extends State<EditLaporan> {
  var url = SpUtil.getString("url") ?? '';
  late TextEditingController idController;
  late TextEditingController tglController;
  late TextEditingController jammulaiController;
  late TextEditingController jamselesaiController;
  late TextEditingController kegiatanController;
  final bool _isLoading = false;

  // Helper function untuk parsing waktu yang aman
  String parseTimeToHHMM(String timeString) {
    try {
      if (timeString.isEmpty) {
        return '00:00';
      }
      
      // Jika sudah dalam format HH:mm
      if (timeString.length == 5 && timeString.contains(':')) {
        // Validasi format HH:mm
        List<String> parts = timeString.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return timeString;
          }
        }
      }
      
      // Jika dalam format HH:mm:ss
      if (timeString.length == 8 && timeString.split(':').length == 3) {
        DateTime parsedTime = DateFormat('HH:mm:ss').parse(timeString);
        return DateFormat('HH:mm').format(parsedTime);
      }
      
      // Jika dalam format HH:mm
      if (timeString.length == 5 && timeString.split(':').length == 2) {
        DateTime parsedTime = DateFormat('HH:mm').parse(timeString);
        return DateFormat('HH:mm').format(parsedTime);
      }
      
      // Jika format tidak dikenali, return default
      return '00:00';
      
    } catch (e) {
      return '00:00';
    }
  }

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.data['id'].toString());
    tglController = TextEditingController(text: widget.data['tgl'].toString());
    
    // Parse waktu dengan aman
    String jammulaiText = parseTimeToHHMM(widget.data['jammulai'].toString());
    String jamselesaiText = parseTimeToHHMM(widget.data['jamselesai'].toString());
    
    jammulaiController = TextEditingController(text: jammulaiText);
    jamselesaiController = TextEditingController(text: jamselesaiText);
    kegiatanController = TextEditingController(text: widget.data['kegiatan'].toString());
     
  }

  @override
  void dispose() {
    idController.dispose();
    tglController.dispose();
    jammulaiController.dispose();
    jamselesaiController.dispose();
    kegiatanController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final sendUrl = '$url/api/update-lhk/${widget.data['id']}';
    final headers = {'Content-Type': 'application/json'};

    // Validasi input waktu
    String jammulaiText = jammulaiController.text.trim();
    String jamselesaiText = jamselesaiController.text.trim();

    if (jammulaiText.isEmpty || jamselesaiText.isEmpty) {
      Alert.alerterror(context, 'Jam mulai dan jam selesai harus diisi');
      return;
    }

    // Validasi format waktu HH:mm
    RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(jammulaiText) || !timeRegex.hasMatch(jamselesaiText)) {
      Alert.alerterror(context, 'Format waktu harus HH:mm (contoh: 14:30)');
      return;
    }

    try {
      // Parse waktu untuk validasi
      DateTime jamMulaiTime = DateFormat("HH:mm").parse(jammulaiText);
      DateTime jamSelesaiTime = DateFormat("HH:mm").parse(jamselesaiText);
      
      // Validasi jam mulai tidak boleh lebih besar dari jam selesai
      if (jamMulaiTime.isAfter(jamSelesaiTime) || jamMulaiTime.isAtSameMomentAs(jamSelesaiTime)) {
        Alert.alerterror(context, 'Jam mulai harus lebih kecil dari jam selesai');
        return;
      }

      // Validasi dengan jam kerja (jika ada)
      String? jamMasukStr = SpUtil.getString('masuk');
      String? jamPulangStr = SpUtil.getString('pulang');
      
      if (jamMasukStr != null && jamMasukStr.isNotEmpty) {
        try {
          DateTime jamMasukTime = DateFormat("HH:mm").parse(jamMasukStr);
          if (jamMulaiTime.isBefore(jamMasukTime)) {
            Alert.alerterror(context, 'Jam mulai tidak boleh lebih kecil dari jam masuk ($jamMasukStr)');
            return;
          }
        } catch (e) {
          print('Error parsing jam masuk: $e');
        }
      }

      if (jamPulangStr != null && jamPulangStr.isNotEmpty) {
        try {
          DateTime jamPulangTime = DateFormat("HH:mm").parse(jamPulangStr);
          if (jamSelesaiTime.isAfter(jamPulangTime)) {
            Alert.alerterror(context, 'Jam selesai tidak boleh lebih besar dari jam pulang ($jamPulangStr)');
            return;
          }
        } catch (e) {
          print('Error parsing jam pulang: $e');
        }
      }

      // Mempersiapkan body request
      final body = json.encode({
        'id': widget.data['id'],
        'tgl': tglController.text,
        'id_user': idUser,
        'jammulai': jammulaiText,
        'jamselesai': jamselesaiText,
        'rincian_kegiatan': kegiatanController.text,
        'status': widget.data['status'],
      });

      // print('Sending data: $body');

      final response = await http.put(Uri.parse(sendUrl), headers: headers, body: body);

      var data = jsonDecode(response.body);
      // print('Response: $data');
      
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          widget.onUpdate();
          if (mounted){
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(initialIndex: 3),
              ),
            );
          Alert.alertsuccess(context, data['message']);
          }
        } else {
          Alert.alertwarning(context, data['message']);
        }
      } else {
        Alert.alerterror(context, 'Gagal mengupdate laporan (Status: ${response.statusCode})');
      }
    } catch (error) {
      print('Error in _saveChanges: $error');
      Alert.alerterror(context, 'Gagal mengupdate laporan: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
        title: const Text(
          'Edit Laporan',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: jammulaiController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.timer),
                            labelText: "Jam Mulai",
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          readOnly: true,
                          onTap: () async {
                            // Parse current time untuk initial value
                            TimeOfDay initialTime = TimeOfDay.now();
                            try {
                              if (jammulaiController.text.isNotEmpty) {
                                List<String> parts = jammulaiController.text.split(':');
                                if (parts.length == 2) {
                                  initialTime = TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: int.parse(parts[1]),
                                  );
                                }
                              }
                            } catch (e) {
                              print('Error parsing initial time: $e');
                            }

                            TimeOfDay? pickedTime = await showTimePicker(
                              initialTime: initialTime,
                              context: context,
                            );

                            if (pickedTime != null) {
                              String formattedTime =
                                  "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                              setState(() {
                                jammulaiController.text = formattedTime;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: jamselesaiController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.timer),
                            labelText: "Jam Selesai",
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          readOnly: true,
                          onTap: () async {
                            // Parse current time untuk initial value
                            TimeOfDay initialTime = TimeOfDay.now();
                            try {
                              if (jamselesaiController.text.isNotEmpty) {
                                List<String> parts = jamselesaiController.text.split(':');
                                if (parts.length == 2) {
                                  initialTime = TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: int.parse(parts[1]),
                                  );
                                }
                              }
                            } catch (e) {
                              print('Error parsing initial time: $e');
                            }

                            TimeOfDay? pickedTime = await showTimePicker(
                              initialTime: initialTime,
                              context: context,
                            );

                            if (pickedTime != null) {
                              String formattedTime =
                                  "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                              setState(() {
                                jamselesaiController.text = formattedTime;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.black45,
                      child: TextFormField(
                        controller: kegiatanController,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const CircularProgressIndicator()
                            : const Icon(
                                Icons.save_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isLoading ? 'Loading...' : 'Simpan',
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
                        onPressed: _isLoading ? null : _saveChanges,
                        clipBehavior: Clip.hardEdge,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 17, 110, 160),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('1. Jam mulai sesuaikan dengan jam absen masuk'),
                      Text('2. Jam mulai tidak lebih besar dari jam selesai'),
                      Text('3. Format waktu harus HH:mm (contoh: 14:30)'),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}