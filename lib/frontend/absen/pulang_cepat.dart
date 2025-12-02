import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sp_util/sp_util.dart';

class PulangCepat extends StatefulWidget {
  const PulangCepat({super.key});

  @override
  State<PulangCepat> createState() => _PulangCepatState();
}

class _PulangCepatState extends State<PulangCepat> {
  int _currentIndex = 0;
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
     final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlueBg = const Color(0xFFE3F2FD);
  final Color redAccent = const Color(0xFFD32F2F);
InputDecoration cleanDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue),
      filled: true,
      fillColor: lightBlueBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: redAccent, width: 1),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
      backgroundColor: primaryBlue, // Background biru agar card menonjol
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparan agar menyatu
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pulang Cepat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10), // Spacer sedikit dari AppBar
          
          // === CARD UTAMA ===
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      // 1. AREA UPLOAD FOTO
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: InteractiveViewer(
                                  child: Image.file(
                                    File(image!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, 
                                         size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 5),
                                    Text("Foto Bukti Pulang Cepat", 
                                         style: TextStyle(color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.camera_alt_rounded, color: Colors.white),
                                label: Text(
                                  _isLoading ? 'Memproses...' : (image == null ? 'Ambil Foto' : 'Ganti Foto'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: _isLoading ? null : () => myAlert(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // 2. INPUT TANGGAL (READONLY)
                      TextFormField(
                        controller: TextEditingController(text:DateFormat('dd/MM/yyyy').format(DateTime.now())), // Pastikan controller ini diisi di initState
                        enabled: false, // Tetap false, tapi styling dipercantik
                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                        decoration: cleanDecoration(
                          label: 'Tanggal Hari Ini', 
                          icon: Icons.calendar_today_rounded
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. DROPDOWN JENIS PULANG CEPAT
                      DropdownButtonFormField<String>(
                        value: _valJenisIzin,
                        decoration: cleanDecoration(
                          label: 'Alasan Pulang Cepat', 
                          icon: Icons.category_outlined
                        ),
                        hint: const Text("Pilih Alasan"),
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
                        validator: (value) => (value == null || value.isEmpty) ? 'Wajib dipilih' : null,
                      ),

                      // Checkbox Khusus Dinas Luar
                      if (_valJenisIzin == 'Dinas Luar')
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 5),
                          child: CheckboxListTile(
                            value: sptSementara,
                            activeColor: primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: Colors.white,
                            title: const Text("SPT Sementara", style: TextStyle(fontWeight: FontWeight.w600)),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                sptSementara = value ?? false;
                              });
                            },
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 4. KETERANGAN
                      TextFormField(
                        controller: keterangan,
                        maxLines: 3,
                        decoration: cleanDecoration(
                          label: 'Keterangan Tambahan', 
                          icon: Icons.edit_note_rounded
                        ).copyWith(alignLabelWithHint: true),
                        validator: (value) => (value == null || value.isEmpty) ? 'Keterangan wajib diisi' : null,
                      ),

                      const SizedBox(height: 30),

                      // 5. TOMBOL SIMPAN
                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Menyimpan...' : 'AJUKAN PULANG CEPAT',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                              letterSpacing: 1
                            ),
                          ),
                          onPressed: _isLoading ? null : _startLoading,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            elevation: 5,
                            shadowColor: primaryBlue.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          if(mounted){
            setState(() {
              _currentIndex = 0;
              SpUtil.putBool('is_PulangCepat', true);
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(initialIndex: _currentIndex),
              ),
            );
            Alert.alertsuccess(context,message);

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
