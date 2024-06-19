import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sp_util/sp_util.dart';

class PulangCepat extends StatefulWidget {
  const PulangCepat({Key? key}) : super(key: key);

  @override
  State<PulangCepat> createState() => _PulangCepatState();
}

class _PulangCepatState extends State<PulangCepat> {
  bool isPulangCepat = false;
  final _formKey = GlobalKey<FormState>();
  bool? sptSementara = false;
  bool _isLoading = false;
  String? _valJenisIzin;
  String? valueIzin;
  String? valueJenisCuti;
  String? valueLamaCuti;
  TextEditingController keterangan = TextEditingController();
  TextEditingController tanggal = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  var url = SpUtil.getString("url");
  var iduser = SpUtil.getString("id_user");
  var iduserpimpinan = SpUtil.getString("id_user_pimpinan");
  var idadmininstansi = SpUtil.getString("id_admin_instansi");

  void _startLoading() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        await kirimizin();
      } catch (error) {
        if (kDebugMode) {
          print("Error: $error");
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    tanggal.text = "";
    super.initState();
    _requestPermissions();
  }

  XFile? image;
  final ImagePicker picker = ImagePicker();

  // We can upload an image from the camera or from the gallery based on the parameter
  Future<void> getImage(ImageSource media) async {
    var img = await picker.pickImage(source: media);

    setState(() {
      image = img;
    });
  }

  // Memeriksa dan meminta izin
  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    final galleryStatus = await Permission.photos.request();

    if (status.isGranted && galleryStatus.isGranted) {
      // Izin diberikan, Anda dapat mengakses kamera dan galeri.
    } else {
      // Izin ditolak, beri tahu pengguna atau tangani dengan sesuai.
    }
  }

  DateTime selectedDate = DateTime.now();
  // Show a popup dialog
  void myAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Please choose media to select'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            child: Column(
              children: [
                ElevatedButton(
                  // If the user clicks this button, they can upload an image from the gallery
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.gallery);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.image),
                      Text('From Gallery'),
                    ],
                  ),
                ),
                ElevatedButton(
                  // If the user clicks this button, they can upload an image from the camera
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.camera);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.camera),
                      Text('From Camera'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final List<String> _jenisIzin = <String>[
    "Dinas Luar",
    "Izin",
    "Sakit",
    "IDLK",
  ];

  // void _validateAndSubmitForm() {
  //   if (image == null) {
  //     _showAlertDialog('Info', 'Gambar tidak boleh kosong.');
  //     return;
  //   }
  //   if (_valJenisIzin == null || _valJenisIzin!.isEmpty) {
  //     _showAlertDialog('Info', 'Jenis izin belum di pilih.');
  //     return;
  //   }
  //   if (durasi.text.isEmpty) {
  //     _showAlertDialog('Info', 'Durasi belum diisi.');
  //     return;
  //   }
  //   if (keterangan.text.isEmpty) {
  //     _showAlertDialog('Info', 'Keterangan belum diisi.');
  //     return;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulang Cepat'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                  child: Container(
                    child: TextFormField(
                      controller: TextEditingController(
                          text:
                              DateFormat('dd/MM/yyyy').format(DateTime.now())),
                      enabled: false, // Mengatur agar tidak dapat diedit
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText:
                              'Jenis Pulang Cepat', // Add a label for clarity.
                        ),
                        value: _valJenisIzin,
                        hint: const Text("Jenis Pulang Cepat"),
                        items: _jenisIzin.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _valJenisIzin = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_valJenisIzin == 'Dinas Luar')
                      Padding(
                        padding: const EdgeInsets.only(left: 65),
                        child: CheckboxListTile(
                          value: sptSementara,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? value) {
                            setState(() {
                              sptSementara = value ?? false;
                            });
                          },
                          title: const Text("SPT Sementara"),
                        ),
                      )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: TextFormField(
                      controller: keterangan,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Keterangan tidak boleh kosong';
                        }
                        return null;
                      },

                      maxLines: 2, //or null
                      decoration: InputDecoration(
                        labelText: "Masukkan keterangan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1, // Skala minimum (zoom out)
                  maxScale: 2.0, // Skala maksimum (zoom in)
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image != null
                        ? Image.file(
                            File(image!.path),
                            fit: BoxFit.cover,
                            width: 300,
                            height: 300,
                          )
                        : Container(), // You can replace this with a placeholder widget or null widget
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    myAlert();
                  },
                  child: const Text('Upload Photo'),
                ),
                SizedBox(
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
                  style:
                      ElevatedButton.styleFrom(fixedSize: const Size(140, 40)),
                ),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void resetState() {
    setState(() {
      image = null;
      tanggal.clear();
      keterangan.clear();
      _valJenisIzin = null;
    });
  }

  Future<void> kirimizin() async {
    String keteranganValue = keterangan.text;
    String imagePath = image!.path;
    // String fileName = imagePath.split('/').last;
    String? idUser = SpUtil.getString("id_user");
    String? idadmininstansi = SpUtil.getString("id_admin_instansi");
    String? jenisIzin = _valJenisIzin;
    String? idAtasan = SpUtil.getString("id_user_pimpinan");
    // Buat multipart request
    var request = http.MultipartRequest(
        'POST', Uri.parse('$url/api/kirim-pulang-cepat/$idUser'));

    // Tambahkan file gambar
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    // Tambahkan data lainnya
    request.fields['id_user'] = idUser!;
    request.fields['id_admin_instansi'] = idadmininstansi!;
    request.fields['keterangan'] = keteranganValue;
    request.fields['status'] = jenisIzin!;
    request.fields['id_atasan'] = idAtasan!;

    try {
      // Kirim permintaan
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = data["message"];
        if (data['status'] == 'success') {
          // ignore: use_build_context_synchronously
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: message,
          );
          SpUtil.putBool('is_PulangCepat', true);
          resetState();
          // Future.delayed(Duration.zero, () {
          //   Navigator.pop(context);
          // });
        } else {
          // ignore: use_build_context_synchronously
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text: message,
          );
        }
      } else {
        // ignore: use_build_context_synchronously
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Foto sudah ada, silahkan cek riwayat',
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Terjadi kesalahan silahkan coba kembali $e',
      );
    }
  }
}
