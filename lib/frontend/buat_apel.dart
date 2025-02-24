import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:flutter/scheduler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobileabsensi/core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sp_util/sp_util.dart';

class BuatApel extends StatefulWidget {
  const BuatApel({super.key});

  @override
  State<BuatApel> createState() => _BuatApelState();
}

class _BuatApelState extends State<BuatApel> {
  var iduser = SpUtil.getString("id_user");
  var iduserpimpinan = SpUtil.getString("id_user_pimpinan");
  var idadmininstansi = SpUtil.getString("id_admin_instansi");
  var url = SpUtil.getString("url");
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  TextEditingController keterangan = TextEditingController();

  void _startLoading() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        await kirimApel();
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

  Future<void> kirimApel() async {
    var keteranganValue = keterangan.text;
    var imagePath = image!.path;
    var idUser = SpUtil.getString("id_user") ?? '';
    var idadmininstansi = SpUtil.getString("id_admin_instansi") ?? '';
    var idAtasan = SpUtil.getString("id_user_pimpinan") ?? '';
    var addimageUrl ='$url/api/apel-post/$idUser';

    Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };
    try {
      Uint8List? compressedImageBytes =
          await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 70
      );
      // var data = {
      //   'id_admin': idadmininstansi,
      //   'id_atasan': idAtasan,
      //   'id_user': idUser,
      //   'keterangan': keteranganValue,
      //   'file': imagePath,
      // };
      // print(data);
      var request = http.MultipartRequest('POST', Uri.parse(addimageUrl))
        ..fields.addAll({
          'id_admin': idadmininstansi,
          'id_atasan': idAtasan,
          'id_user': idUser,
          'keterangan': keteranganValue,
        })
        ..headers.addAll(headers)
        ..files.add(http.MultipartFile.fromBytes('file', compressedImageBytes!,
            filename: 'compressed_image.jpg'));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);



      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = data["message"];
        if (data['status'] == 'success') {
          if(mounted)
          {QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: message,
          ); 
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const Apel()));}
        } else if (data['status'] == false) {
          if(mounted)
          {QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text: message,
          );}
        }
      } else {
         if(mounted)
        {QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Terjadi kesalahan coba kembali',
        );}
      }
    } catch (e) {
       if(mounted)
      {QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Terjadi kesalahan silahkan coba kembali',
      );}
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  XFile? image;
  final ImagePicker picker = ImagePicker();

  Future<void> getImage(ImageSource media) async {
    var img = await picker.pickImage(source: media);

    setState(() {
      image = img;
    });
  }

  // Memeriksa dan meminta Apel
  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    final galleryStatus = await Permission.photos.request();

    if (status.isGranted && galleryStatus.isGranted) {
      // Apel diberikan, Anda dapat mengakses kamera dan galeri.
    } else {
      // Apel ditolak, beri tahu pengguna atau tangani dengan sesuai.
    }
  }

  // Show a popup dialog
  void myAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Center(child: Text('Pilih media')),
          content: SizedBox(
            height: 50,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.camera);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.camera),
                      Text(' Dari Kamera'),
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

  // void _validateAndSubmitForm() {
  //   if (image == null) {
  //     _showAlertDialog('Info', 'Gambar tidak boleh kosong.');
  //     return;
  //   }
  //   if (_valJenisApel == null || _valJenisApel!.isEmpty) {
  //     _showAlertDialog('Info', 'Jenis Apel belum di pilih.');
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
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Buat Apel',style: TextStyle(color: Colors.white)),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.1,
                    maxScale: 2.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image != null
                          ? Image.file(
                              File(image!.path),
                              fit: BoxFit.cover,
                              width: 300,
                              height: 300,
                            )
                          : Container(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      myAlert();
                    },
                    child: const Text('Ambil Gambar'),
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
                                  
                    maxLines: 6, //or null
                    decoration: InputDecoration(
                      labelText: "Masukkan keterangan",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                    clipBehavior: Clip.hardEdge,
                    onPressed: _isLoading
                        ? null
                        : _startLoading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 1, 50, 106),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 45, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      _isLoading ? 'Loading...' : 'Simpan',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 16.0,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
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
      keterangan.clear();
    });
  }
}
