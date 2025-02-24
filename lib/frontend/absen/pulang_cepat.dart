import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sp_util/sp_util.dart';

class PulangCepat extends StatefulWidget {
  const PulangCepat({super.key});

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
            if (image == null) {
      Alert.alertwarning(context,'Foto tidak boleh kosong.');
      return;
    }
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
  ];

  // void _validateAndSubmitForm() {
  //   if (image == null) {
  //     Alert.alertwarning(context,'Gambar tidak boleh kosong.');
  //     return;
  //   }
  //   if (_valJenisIzin == null || _valJenisIzin!.isEmpty) {
  //     Alert.alertwarning(context,'Jenis izin belum di pilih.');
  //     return;
  //   }
  //   if (keterangan.text.isEmpty) {
  //     Alert.alertwarning(context,'Keterangan belum diisi.');

  //     return;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Pulang Cepat',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
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
                  ElevatedButton.icon(
                      icon: const Icon(Icons.image_search_rounded,size: 20,color: Colors.white,),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Unggah Foto',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1))
                        ]),
                      ),
                      onPressed: _isLoading ? null : () {
                        myAlert();
                      },
                      clipBehavior: Clip.hardEdge,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 0, 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: TextEditingController(
                        text:
                            DateFormat('dd/MM/yyyy').format(DateTime.now())),
                    enabled: false, // Mengatur agar tidak dapat diedit
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
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
                  TextFormField(
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
                  const SizedBox(
                    height: 20,
                  ),
                  
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.save_outlined,size: 20,color: Colors.white,),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Simpan',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1))
                        ]),
                      ),
                      onPressed: _isLoading ? null : _startLoading,
                      clipBehavior: Clip.hardEdge,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 17, 110, 160),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  )
                ],
              ),
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
        setState(() {
          SpUtil.putBool('is_PulangCepat', true);
        });
        final data = jsonDecode(response.body);
        String message = data["message"];
        if (data['status'] == 'success') {
          if(mounted){
            Alert.alertsuccess(context,message);
            Navigator.pop(context, true);
            SpUtil.putBool('is_PulangCepat', true);
            resetState();
          }
        } else {
          if(mounted){
            Alert.alertwarning(context,message);
          }
        }
      } else {
        if(mounted){
            Alert.alerterror(context,'Foto sudah ada, silahkan cek riwayat');
          }
      }
    } catch (e) {
      if(mounted){
            Alert.alerterror(context,'Terjadi kesalahan silahkan coba kembali');
          }
    }
  }
}
