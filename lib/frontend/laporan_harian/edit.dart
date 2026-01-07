import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/core/constants/app_constants.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'dart:convert';

import 'package:sp_util/sp_util.dart';

class EditLaporan extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpdate;

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

  String parseTimeToHHMM(String timeString) {
    try {
      if (timeString.isEmpty) {
        return '00:00';
      }

      if (timeString.length == 5 && timeString.contains(':')) {
        List<String> parts = timeString.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return timeString;
          }
        }
      }

      if (timeString.length == 8 && timeString.split(':').length == 3) {
        DateTime parsedTime = DateFormat('HH:mm:ss').parse(timeString);
        return DateFormat('HH:mm').format(parsedTime);
      }

      if (timeString.length == 5 && timeString.split(':').length == 2) {
        DateTime parsedTime = DateFormat('HH:mm').parse(timeString);
        return DateFormat('HH:mm').format(parsedTime);
      }

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

    String jammulaiText = parseTimeToHHMM(widget.data['jammulai'].toString());
    String jamselesaiText = parseTimeToHHMM(widget.data['jamselesai'].toString());

    jammulaiController = TextEditingController(text: jammulaiText);
    jamselesaiController = TextEditingController(text: jamselesaiText);
    kegiatanController = TextEditingController(text: widget.data['rincian_kegiatan'].toString());
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
    final sendUrl = '$url/api/update-lhk/${SpUtil.getString('id_user')}/${widget.data['id']}';
    final headers = {
      'Content-Type': 'application/json'
    };
    String jammulaiText = jammulaiController.text.trim();
    String jamselesaiText = jamselesaiController.text.trim();

    if (jammulaiText.isEmpty || jamselesaiText.isEmpty) {
      Alert.alerterror(context, 'Jam mulai dan jam selesai harus diisi');
      return;
    }

    RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(jammulaiText) || !timeRegex.hasMatch(jamselesaiText)) {
      Alert.alerterror(context, 'Format waktu harus HH:mm (contoh: 14:30)');
      return;
    }

    try {

      final body = json.encode({
        'id': widget.data['id'],
        'tgl': tglController.text,
        'id_user': idUser,
        'jammulai': jammulaiText,
        'jamselesai': jamselesaiText,
        'rincian_kegiatan': kegiatanController.text,
        'status': widget.data['status'],
      });

      final response = await http.put(Uri.parse(sendUrl), headers: headers, body: body);

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          widget.onUpdate();
          if (mounted) {
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
        Alert.alerterror(context, 'Gagal mengupdate laporan, silakan coba lagi.');
      }
    } catch (error) {
      Alert.alerterror(context, 'Gagal mengupdate laporan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1565C0);
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeField(
                            context: context,
                            controller: jammulaiController,
                            label: "Jam Mulai",
                            icon: Icons.timer,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTimeField(
                            context: context,
                            controller: jamselesaiController,
                            label: "Jam Selesai",
                            icon: Icons.timer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: kegiatanController,
                      validator: (value) => (value == null || value.isEmpty) ? 'Kegiatan wajib diisi' : null,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Deskripsi Kegiatan",
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: Icon(Icons.assignment_outlined, color: primaryBlue),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'SIMPAN LAPORAN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      ),
    );
  }

  Widget _buildTimeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final Color primaryBlue = const Color(0xFF1565C0);
    final Color lightBlueBg = const Color(0xFFE3F2FD);

    return TextFormField(
      controller: controller,
      readOnly: true,
      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: lightBlueBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
      onTap: () async {
        TimeOfDay initialTime = TimeOfDay.now();
        try {
          if (controller.text.isNotEmpty) {
            List<String> parts = controller.text.split(':');
            if (parts.length == 2) {
              initialTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
          }
        } catch (e) {
          debugPrint('Error parsing time: $e');
        }

        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

          controller.text = formattedTime;
        }
      },
    );
  }
}
