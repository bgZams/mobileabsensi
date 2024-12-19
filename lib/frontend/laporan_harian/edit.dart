import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/main.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'dart:convert';

import 'package:sp_util/sp_util.dart';

class EditLaporan extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpdate; // Callback function

  const EditLaporan({Key? key, required this.data, required this.onUpdate})
      : super(key: key);

  @override
  _EditLaporanState createState() => _EditLaporanState();
}

class _EditLaporanState extends State<EditLaporan> {
  var url = SpUtil.getString("url") ?? '';
  late TextEditingController idController;
  late TextEditingController tglController;
  late TextEditingController jammulaiController;
  late TextEditingController jamselesaiController;
  late TextEditingController kegiatanController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.data['id']);
    tglController = TextEditingController(text: widget.data['tgl']);
    jammulaiController = TextEditingController(text: DateFormat('HH:mm').format(DateFormat('HH:mm').parse(widget.data['jammulai'].toString())));
    jamselesaiController = TextEditingController(text: DateFormat('HH:mm').format(DateFormat('HH:mm').parse(widget.data['jamselesai'].toString())));
    kegiatanController = TextEditingController(text: widget.data['kegiatan']);
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
    // Parsing waktu dari controller text
    var mulai = DateFormat('HH:mm').parse(jammulaiController.text);
    var selesai = DateFormat('HH:mm').parse(jamselesaiController.text);
    // Format kembali DateTime ke string dengan format yang sesuai
    String formattedMulai = DateFormat('HH:mm').format(mulai);
    String formattedSelesai = DateFormat('HH:mm').format(selesai);
    // Mempersiapkan body request
    final body = json.encode({
      'id': widget.data['id'],
      'tgl': tglController.text,
      'id_user': idUser,
      'jammulai': formattedMulai,
      'jamselesai': formattedSelesai,
      'rincian_kegiatan': kegiatanController.text,
      'status': widget.data['status'],
    });

    DateTime jamMulaiTime = DateFormat("HH:mm").parse(formattedMulai);
    DateTime jamSelesaiTime = DateFormat("HH:mm").parse(formattedSelesai);
    DateTime jamMasukTime = DateFormat("HH:mm").parse(SpUtil.getString('masuk').toString());
    DateTime jamPulangTime = DateFormat("HH:mm").parse(SpUtil.getString('pulang').toString());

    if (jamMulaiTime.isBefore(jamMasukTime)) {
      Alert.alerterror(context, 'Jam mulai tidak boleh lebih kecil dari jam masuk');
      return;
    }
    if (jamSelesaiTime.isAfter(jamPulangTime)) {
      Alert.alerterror(context, 'Jam selesai tidak boleh lebih besar dari jam pulang');
      return;
    }

    try {
      final response =
          await http.put(Uri.parse(sendUrl), headers: headers, body: body);

      var data = jsonDecode(response.body);
      print(data);
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          // ignore: use_build_context_synchronously
          Alert.alertsuccess(context, data['message']);
          widget.onUpdate();
          // ignore: use_build_context_synchronously
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        } else {
          Alert.alertwarning(context, data['message']);
        }
      } else {
        throw Exception('Failed to update report');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
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
                            TimeOfDay? pickedTime = await showTimePicker(
                              initialTime: TimeOfDay.now(),
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
                            TimeOfDay? pickedTime = await showTimePicker(
                              initialTime: TimeOfDay.now(),
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
