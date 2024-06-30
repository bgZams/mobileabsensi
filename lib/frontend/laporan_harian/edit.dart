import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'dart:convert';

import 'package:sp_util/sp_util.dart';

class EditLaporan extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpdate; // Callback function

  const EditLaporan({Key? key, required this.data, required this.onUpdate}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.data['id']);
    tglController = TextEditingController(text: widget.data['tgl']);
    jammulaiController = TextEditingController(text: widget.data['jammulai']);
    jamselesaiController = TextEditingController(text: widget.data['jamselesai']);
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
    final body = json.encode({
      'id': widget.data['id'],
      'tgl': tglController.text,
      'jammulai': jammulaiController.text,
      'jamselesai': jamselesaiController.text,
      'kegiatan': kegiatanController.text,
      'status': widget.data['status'],
    });

    try {
      final response = await http.put(Uri.parse(sendUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = json.encode(data["message"]).replaceAll('"', '');
        // ignore: use_build_context_synchronously
        Alert.alertsuccess(context, message);
        widget.onUpdate(); // Panggil callback untuk memberitahu bahwa data diperbarui
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Kembali ke halaman sebelumnya
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
        title: const Text('Edit Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
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
                          String formattedTime = "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}";
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
                          String formattedTime = "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}";
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
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan', style: TextStyle(fontSize: 14)),
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(fixedSize: const Size(140, 40)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
