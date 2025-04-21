import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobileabsensi/services/alert.dart';
// import 'package:mobileabsensi/core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sp_util/sp_util.dart';

class BuatIzin extends StatefulWidget {
  const BuatIzin({super.key});

  @override
  State<BuatIzin> createState() => _BuatIzinState();
}

class _BuatIzinState extends State<BuatIzin> {
  var url = SpUtil.getString("url");
  var iduser = SpUtil.getString("id_user");
  var idinstansi = SpUtil.getString("id_instansi");
  var iduserpimpinan = SpUtil.getString("id_user_pimpinan");
  var idadmininstansi = SpUtil.getString("id_admin_instansi");
  var username = SpUtil.getString("username");
  var usernameadmin = SpUtil.getString("username_admin");
  var namalengkap = SpUtil.getString("nama_lengkap");
  var namainstansi = SpUtil.getString("nama_instansi");
  final _formKey = GlobalKey<FormState>();
  bool? sptSementara = false;
  bool _isLoading = false;
  final bool _isLoadingMedia = false;
  String? _valJenisIzin;
  String? valueIzin;
  String? valueJenisCuti;
  String? valueLamaCuti;
  TextEditingController durasi = TextEditingController();
  TextEditingController keterangan = TextEditingController();
  TextEditingController tanggal = TextEditingController();

  void _startLoading() async {
    setState(() {
      _isLoading = true; // Menampilkan loader sebelum memulai pengiriman data
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

  // Show a popup dialog
  void myAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Pilih media'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.gallery);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.image),
                      Text(' Galeri'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.camera);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.camera),
                      Text(' Kamera'),
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
    "Cuti",
    "IDLK",
  ];

  final List<String> _jenisCuti = <String>[
    "Cuti Tahunan",
    "Cuti Sakit",
    "Cuti Alasan Penting",
    "Cuti Besar",
    "Cuti Melahirkan",
    "Cuti Diluar Tanggungan Negara",
  ];

  final List<String> _lamaCuti = <String>[
    "HARIAN",
    "BULANAN",
    "TAHUNAN",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
        title: const Text('Buat Izin',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),),
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
                        : Container(  ),
                  ),
                ),
                ElevatedButton.icon(
                      icon: _isLoadingMedia
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.image_search_rounded,size: 20,color: Colors.white,),
                      label: Text(
                        _isLoadingMedia ? 'Loading...' : 'Unggah Foto Izin',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1))
                        ]),
                      ),
                      onPressed: _isLoadingMedia ? null : () {
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Jenis Izin',
                          ),
                          value: _valJenisIzin,
                          hint: const Text("Pilih jenis izin"),
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
                    else if (_valJenisIzin == 'Cuti')
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Cuti',
                                ),
                                value: valueJenisCuti,
                                hint: const Text("Pilih jenis cuti"),
                                items: _jenisCuti.map((String valjenisCuti) {
                                  return DropdownMenuItem<String>(
                                    value: valjenisCuti,
                                    child: Text(valjenisCuti),
                                  );
                                }).toList(),
                                onChanged: (String? valjenisCuti) {
                                  setState(() {
                                    valueJenisCuti = valjenisCuti;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Jenis Cuti tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText:
                                    'Lama Cuti', // Add a label for clarity.
                              ),
                              value: valueLamaCuti,
                              hint: const Text("Pilih lama cuti"),
                              items: _lamaCuti.map((String valLamaCuti) {
                                return DropdownMenuItem<String>(
                                  value: valLamaCuti,
                                  child: Text(valLamaCuti),
                                );
                              }).toList(),
                              onChanged: (String? valLamaCuti) {
                                setState(() {
                                  valueLamaCuti = valLamaCuti;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lama cuti boleh kosong';
                                }
                                return null;
                              },
                            ),
                          )
                        ],
                      ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                if (_valJenisIzin == 'IDLK')
                  Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      enabled: false,
                      controller: tanggal,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.calendar_today), // icon of text field
                        labelText: tanggal.text.isNotEmpty ? tanggal.text : DateTime.now().toLocal().toString().split(' ')[0], // menampilkan tanggal yang dipilih
                      ),
                      onTap: () async {
                        DateTimeRange? pickedDate = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            tanggal.text =
                                '${pickedDate.start.toLocal().toString().split(' ')[0]} - ${pickedDate.end.toLocal().toString().split(' ')[0]}';
                            durasi.text = (pickedDate.end.difference(pickedDate.start).inDays + 1).toString();
                          });
                        }
                      },
                    ),
                  ),
                )
                else

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: tanggal,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today), // icon of text field
                        labelText: "Pilih tanggal",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal tidak boleh kosong';
                        }
                        return null;
                      },
                      readOnly: true,
                      onTap: () async {
                        DateTimeRange? pickedDate = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            tanggal.text =
                                '${pickedDate.start.toLocal().toString().split(' ')[0]} - ${pickedDate.end.toLocal().toString().split(' ')[0]}';
                            durasi.text = (pickedDate.end.difference(pickedDate.start).inDays + 1).toString();
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_valJenisIzin == 'IDLK')
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(height: 1))
                else
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: durasi,
                      decoration: const InputDecoration.collapsed(
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        hintText: 'Durasi',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Durasi tidak boleh kosong';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Hanya angka yang diperbolehkan';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      enabled: false,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),


                Container(
                  padding: const EdgeInsets.all(10),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: TextFormField(
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
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
      durasi.clear();
      _valJenisIzin = null;
    });
  }

  Future<void> kirimizin() async {

    // Ambil nilai dari inputan
    String imagePath = image!.path;
    String tanggalTerpilih = tanggal.text.split(' - ')[0];
    String keteranganValue = keterangan.text;
    String durasiValue = durasi.text;

    // String fileName = imagePath.split('/').last;
    String? idUser = SpUtil.getString("id_user");
    String? idadmininstansi = SpUtil.getString("id_admin_instansi");
    String? jenisIzin = _valJenisIzin;
    String? idAtasan = SpUtil.getString("id_user_pimpinan");
    String namalengkap = SpUtil.getString("nama_lengkap").toString();
    // Buat multipart request
    var request =
        http.MultipartRequest('POST', Uri.parse('$url/api/izin/kirim-izin/$iduser'));
    // Tambahkan file gambar
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));
    // Tambahkan data lainnya
    request.fields['tgl_absen'] = tanggalTerpilih;
    request.fields['id_user'] = idUser!;
    request.fields['nama_lengkap'] = namalengkap;
    request.fields['id_admin_instansi'] = idadmininstansi!;
    request.fields['keterangan'] = keteranganValue;
    request.fields['status'] = jenisIzin!;
    request.fields['durasi'] = durasiValue;
    request.fields['id_atasan'] = idAtasan!;
    Map<String, dynamic> addFirebaseIzin = {
      'tanggal': tanggalTerpilih,
      'id_user': iduser,
      'id_atasan': iduserpimpinan,
      'id_status': 0,
      'nama_lengkap': namalengkap,
      'jenis_izin': _valJenisIzin,
      'key_notif': 'izin',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      // 'timestamp': DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()),
    }; 
     
    try {
      // Kirim permintaan
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Jika berhasil
        final DatabaseReference databaseReference =
            FirebaseDatabase.instance.ref();
        databaseReference.child("izin").push().set(addFirebaseIzin);
        final data = jsonDecode(response.body);
        String message = data["message"];
        if (data['status'] == 'success') {
          if(mounted){

            Navigator.pop(context, true);
            Alert.alertsuccess(context,message);
            SpUtil.putInt('idlk', 1);

          }
        } else {
          if(mounted){
            Alert.alertwarning(context,message);
          }
        }
      } else {
        if(mounted){
            Alert.alerterror(context,'Tidak dapat terhubung ke server');
          }
      }
    } catch (e) {
      if(mounted){
        Alert.alerterror(context,'Terjadi kesalahan silahkan coba kembali');
      }
    }
  }
}
