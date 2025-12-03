import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
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
    print(SpUtil.getBool('is_codeMasuk'));

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

List<String> getJenisIzin() {
  bool allowIDLK = SpUtil.getBool('is_codeMasuk') == true;

  final List<String> base = [
    "Dinas Luar",
    "Izin",
    "Sakit",
    "Cuti",
    "Tugas Belajar",
  ];

  if (allowIDLK) {
    base.add("IDLK");
  }

  return base;
}


  final List<String> _jenisCuti = <String>[
    "Cuti Tahunan",
    "Cuti Sakit",
    "Cuti Alasan Penting",
    "Cuti Besar",
    "Cuti Melahirkan",
    "Cuti Diluar Tanggungan Negara",
    "Cuti Belajar",
  ];
 

  @override
  Widget build(BuildContext context) { 
      final size = MediaQuery.of(context).size;
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
      fillColor: lightBlueBg, // Background biru muda
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
    return Scaffold(
    backgroundColor: primaryBlue, // Background dasar biru agar card terlihat pop-up
    body: Stack(
      children: [
        // Navbar Custom Anda
        WidgetNavbar(title: 'Buat Izin'),
        
        Column(
          children: [
            // Spacer untuk memberi jarak header
            SizedBox(height: size.height * 0.12), // Sedikit dinaikkan agar proporsional
            
            // === CARD PUTIH UTAMA ===
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
                      blurRadius: 15,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        
                        // === 1. AREA UPLOAD FOTO ===
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              if (image != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(image!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, 
                                           size: 50, color: Colors.grey.shade400),
                                      const SizedBox(height: 5),
                                      Text("Belum ada foto", 
                                           style: TextStyle(color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 10),
                              
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _isLoadingMedia
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.camera_alt_rounded, color: Colors.white),
                                  label: Text(
                                    _isLoadingMedia ? 'Memproses...' : (image == null ? 'Ambil Foto' : 'Ganti Foto'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: _isLoadingMedia ? null : () { myAlert(); },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: redAccent, // Merah untuk aksi media
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // === 2. DROPDOWN JENIS IZIN ===
                        DropdownButtonFormField<String>(
                      value: _valJenisIzin,
                      decoration: cleanDecoration(
                        label: 'Jenis Izin',
                        icon: Icons.assignment_ind_outlined,
                      ),
                      hint: const Text("Pilih jenis izin"),
                      items: getJenisIzin().map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
  setState(() {
    _valJenisIzin = value;
    valueJenisCuti = null;

    if (value == 'IDLK') {
      final now = DateTime.now();
      final today = now.toString().split(' ')[0];

      tanggal.text = '$today - $today';
      durasi.text = '1 Hari';
    } else {
      tanggal.clear();
      durasi.clear();
    }
  });
},

                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib dipilih' : null,
                    ),


                        // === LOGIKA TAMPILAN TAMBAHAN (CUTI / DINAS) ===
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

                        if (_valJenisIzin == 'Cuti')
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: DropdownButtonFormField<String>(
                              value: valueJenisCuti,
                              decoration: cleanDecoration(label: 'Jenis Cuti', icon: Icons.beach_access_outlined),
                              hint: const Text("Pilih kategori cuti"),
                              items: _jenisCuti.map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => valueJenisCuti = val),
                              validator: (val) => (val == null || val.isEmpty) ? 'Jenis Cuti wajib dipilih' : null,
                            ),
                          ),

                        const SizedBox(height: 15),

                        // === 3. TANGGAL (DATE RANGE) ===
                        TextFormField(
  controller: tanggal,
  readOnly: true,
  enabled: _valJenisIzin != 'IDLK',
  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
  decoration: cleanDecoration(
    label: (_valJenisIzin == 'IDLK') ? "Tanggal IDLK" : "Pilih Tanggal Mulai - Selesai",
    icon: Icons.calendar_month_outlined,
  ),
  validator: (val) => (val == null || val.isEmpty) ? 'Tanggal wajib diisi' : null,
  onTap: () async {
    if (_valJenisIzin == 'IDLK') return;

    DateTimeRange? pickedDate = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        final start = pickedDate.start.toString().split(' ')[0];
        final end = pickedDate.end.toString().split(' ')[0];

        tanggal.text = '$start - $end';

        final days = pickedDate.end.difference(pickedDate.start).inDays + 1;
        durasi.text = '$days Hari';
      });
    }
  },
),


                        // === 4. DURASI (Hanya tampil jika BUKAN IDLK) ===
                        if (_valJenisIzin != 'IDLK') ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: durasi,
                            readOnly: true, // Otomatis terisi
                            decoration: cleanDecoration(label: 'Total Durasi', icon: Icons.timer_outlined),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Durasi kosong';
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 15),

                        // === 5. KETERANGAN ===
                        TextFormField(
                          controller: keterangan,
                          maxLines: 4,
                          decoration: cleanDecoration(label: 'Keterangan / Alasan', icon: Icons.edit_note_rounded)
                              .copyWith(alignLabelWithHint: true), // Agar label ada di pojok atas
                          validator: (val) => (val == null || val.isEmpty) ? 'Keterangan wajib diisi' : null,
                        ),

                        const SizedBox(height: 30),

                        // === 6. TOMBOL SIMPAN ===
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded, color: Colors.white),
                            label: Text(
                              _isLoading ? 'Menyimpan...' : 'AJUKAN IZIN',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                            ),
                            onPressed: _isLoading ? null : _startLoading,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              elevation: 5,
                              shadowColor: primaryBlue.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                        
                        // Padding bawah agar tidak mepet layar
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      durasi.clear();
      _valJenisIzin = null;
    });
  }
  int _currentIndex = 0; // Define _currentIndex at the class level

  Future<void> kirimizin() async {
    // Ambil nilai dari inputan
    String imagePath = image!.path;
    String tanggalTerpilih = tanggal.text.split(' - ')[0];
    String keteranganValue = keterangan.text;
    String durasiValue = durasi.text;
    String durasiAngkaString = durasiValue.replaceAll(' Hari', '');

    String? idUser = SpUtil.getString("id_user");
    String? idadmininstansi = SpUtil.getString("id_admin_instansi");
    String? jenisIzin = _valJenisIzin;
    String? idAtasan = SpUtil.getString("id_user_pimpinan");
    if(idAtasan == null){
      Alert.alertwarning(context, 'ID Atasan tidak ditemukan');
      return; // Hentikan fungsi jika idAtasan null
    }
    String namalengkap = SpUtil.getString("nama_lengkap").toString();

    // Buat multipart request
    var request =
        http.MultipartRequest('POST', Uri.parse('$url/api/izin/kirim-izin/$idUser')); // <-- Perhatikan $idUser (case sensitive)
    
    // Tambahkan file gambar
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));
    // Tambahkan data lainnya
    request.fields['tgl_absen'] = tanggalTerpilih;
    request.fields['id_user'] = idUser!;
    request.fields['nama_lengkap'] = namalengkap;
    request.fields['id_admin_instansi'] = idadmininstansi!;
    request.fields['keterangan'] = keteranganValue;
    request.fields['status'] = jenisIzin!;
    request.fields['durasi'] = durasiAngkaString;
    request.fields['id_atasan'] = idAtasan; // idAtasan sudah dicek null di atas

    Map<String, dynamic> addFirebaseIzin = {
      'tanggal': tanggalTerpilih,
      'id_user': idUser, // <-- Perbaiki variabel
      'id_atasan': idAtasan, // <-- Perbaiki variabel
      'id_status': 0,
      'nama_lengkap': namalengkap,
      'jenis_izin': _valJenisIzin,
      'jenis_cuti': valueJenisCuti ?? '',
      'key_notif': 'izin',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }; 

    // HAPUS DUA BARIS PENGIRIMAN YANG SEBELUMNYA ADA DI SINI

    try {
      // Kirim permintaan HANYA DI DALAM TRY-CATCH
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final DatabaseReference databaseReference =
            FirebaseDatabase.instance.ref();
        databaseReference.child("izin").push().set(addFirebaseIzin);
        
        final data = jsonDecode(response.body);
        String message = data["message"];
        
        if (data['status'] == 'success') {
          if(mounted){
            setState(() {
              if(jenisIzin == 'IDLK'){
                SpUtil.putInt('idlk', 1);
                SpUtil.putBool('is_IDLK', true);
              }
              _currentIndex = 2;
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
