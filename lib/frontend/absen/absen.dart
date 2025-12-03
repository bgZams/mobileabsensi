import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/absen/pulang_cepat.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:mobileabsensi/widget/widget_fitur.dart';
import 'package:mobileabsensi/widget/widget_header.dart';
import 'package:network_info_plus/network_info_plus.dart';
// import 'package:quickalert/quickalert.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';
import '../../services/alert.dart';

// Enum untuk mengelola state loading tombol absen
enum AbsenLoadingState { none, masuk, pulang }

class Absen extends StatefulWidget {
  const Absen({super.key});

  @override
  State<Absen> createState() => _AbsenState();
}

class _AbsenState extends State<Absen> {
  // --- Konstanta untuk Maintainability ---
  static const String _versiApp = '1.4';

  // Kunci SharedPreferences (SpUtil)
  static const String _spKeyUrl = "url";
  static const String _spKeyIdUser = "id_user";
  static const String _spKeyIdAdmin = "id_admin_instansi";
  static const String _spKeyUsername = "username";
  static const String _spKeyIdInstansi = "id_instansi";
  static const String _spKeyNamaLengkap = "nama_lengkap";
  static const String _spKeyNamaInstansi = "nama_instansi";
  static const String _spKeyIdType = "id_type";
  static const String _spKeyWifiData = "wifi_data";
  static const String _spKeyShiftData = "shift_data";
  static const String _spKeySavedDate = "saved_date";
  static const String _spKeyJamMasuk = "masuk";
  static const String _spKeyJamPulang = "pulang";
  static const String _spKeyIsCodeMasuk = "is_codeMasuk";
  static const String _spKeyIsCodePulang = "is_codePulang";
  static const String _spKeyIsPulangCepat = "is_PulangCepat";
  static const String _spKeyIsIDLK = "is_IDLK";
  static const String _spKeyStatusIdlk = "status_idlk";
  static const String _spKeyStatusPC = "statusPC";
  static const String _spKeyCodePulang = "code_pulang";
  static const String _spKeyIdlkInt = "idlk";

  // --- Variabel State Widget ---
  bool _enabled = true; // Untuk Skeletonizer
  Timer? _timer;
  final NetworkInfo _networkInfo = NetworkInfo();

  // Variabel yang diambil dari SpUtil saat init
  String? url;
  String? idUser;
  String? idAdmin;
  String? nama;
  String? instansi;
  String? jamMasuk;
  String? jamPulang;
  String? code;
  String? wifiBSSID;

  // --- Value Notifiers untuk State Reaktif ---
  final ValueNotifier<String> _jamSekarangNotifier = ValueNotifier('');
  final ValueNotifier<String?> _wifiNameNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isCodeMasukNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCodePulangNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isPulangCepatNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isIDLKNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _notifNotifier = ValueNotifier('0');
  
  // Notifier tunggal untuk mengelola status loading kedua tombol
  final ValueNotifier<AbsenLoadingState> _loadingStateNotifier =
      ValueNotifier(AbsenLoadingState.none);

  @override
  void initState()  {
    super.initState();
    _enabled = false;
    // Muat data dari SharedPreferences
    _loadInitialData();

    _initNetworkInfo();
    _startPeriodicCheck();
    _jamSekarangNotifier.value = _formatDateTime(DateTime.now());

    if (SpUtil.getString(_spKeyIdType) == "1") {
      cekDataShift();
    }
    print(SpUtil.getBool(_spKeyIsCodeMasuk));
    if (SpUtil.getBool(_spKeyIsPulangCepat) == true ||
        SpUtil.getBool(_spKeyIsIDLK) == true) {
      _checkIdlkandPulangCepat();
    }
    _fetchNotif();
    refreshData(); // Mungkin redundan jika _fetchNotif sudah ada, tapi ikuti alur lama
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Dispose semua notifiers
    _jamSekarangNotifier.dispose();
    _wifiNameNotifier.dispose();
    _isCodeMasukNotifier.dispose();
    _isCodePulangNotifier.dispose();
    _isPulangCepatNotifier.dispose();
    _isIDLKNotifier.dispose();
    _notifNotifier.dispose();
    _loadingStateNotifier.dispose();
    super.dispose();
  }

  /// Memuat data awal dari SharedPreferences ke variabel state.
  void _loadInitialData() {
    url = SpUtil.getString(_spKeyUrl);
    idUser = SpUtil.getString(_spKeyIdUser);
    idAdmin = SpUtil.getString(_spKeyIdAdmin) ?? '';
    nama = SpUtil.getString(_spKeyNamaLengkap).toString();
    instansi = SpUtil.getString(_spKeyNamaInstansi).toString();
    jamMasuk = SpUtil.getString(_spKeyJamMasuk);
    jamPulang = SpUtil.getString(_spKeyJamPulang);

    // Inisialisasi notifiers dari SpUtil
    _isCodeMasukNotifier.value = SpUtil.getBool(_spKeyIsCodeMasuk) ?? false;
    _isCodePulangNotifier.value = SpUtil.getBool(_spKeyIsCodePulang) ?? false;
    _isPulangCepatNotifier.value = SpUtil.getBool(_spKeyIsPulangCepat) ?? false;
    _isIDLKNotifier.value = SpUtil.getBool(_spKeyIsIDLK) ?? false;
  }

  // =======================================================================
  // 🕒 Manajemen Waktu dan Jaringan
  // =======================================================================

  void _getCurrentTime() {
    if (mounted) {
      _jamSekarangNotifier.value = _formatDateTime(DateTime.now());
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkNetworkChanges();
      _getCurrentTime(); // Update waktu
    });
  }

  Future<void> _checkNetworkChanges() async {
    try {
      String? currentWifiName = await _networkInfo.getWifiName();
      String? cleanName = currentWifiName?.replaceAll('"', '');

      if (!mounted) return;

      if (cleanName != _wifiNameNotifier.value) {
        _wifiNameNotifier.value = cleanName;
        // Update info lain hanya jika nama WiFi berubah
        wifiBSSID = await _networkInfo.getWifiBSSID();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking network: $e');
      }
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      String? currentWifiName = await _networkInfo.getWifiName();
      wifiBSSID = await _networkInfo.getWifiBSSID();

      if (mounted) {
        _wifiNameNotifier.value = currentWifiName?.replaceAll('"', '');
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wi-Fi Name or BSSID', error: e);
      if (mounted) {
        _wifiNameNotifier.value = 'Gagal mendapatkan info Wi-Fi';
      }
    }
  }

  // =======================================================================
  // 🌐 Fungsi Pengambilan Data (API Calls)
  // =======================================================================

  Future<void> cekDataShift() async {
    try {
      final dataShift = await http.get(
        Uri.parse(
            '$url/api/jam-kerja/${SpUtil.getString(_spKeyIdUser)}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (dataShift.statusCode == 200) {
        final shiftData = json.decode(dataShift.body)['data'];
        SpUtil.putString(_spKeyShiftData, json.encode(shiftData));
      } else {
        developer.log('Gagal memuat data shift: ${dataShift.statusCode}');
      }
    } catch (e) {
      developer.log('Error cekDataShift: $e');
    }
  }

  Future<void> _checkIdlkandPulangCepat() async {
    try {
      if (SpUtil.getBool(_spKeyIsIDLK) == true) {
        final response = await http.get(
          Uri.parse('$url/api/cek/idlk/$idUser'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // ... (Logika SpUtil setString _spKeyStatusIdlk Anda sudah benar)
          SpUtil.putString(_spKeyStatusIdlk, data['data']);
          if (data['data'] == 'pending') {
             SpUtil.putString(_spKeyStatusPC, data['data']);
             SpUtil.putBool(_spKeyIsCodeMasuk, true);
             SpUtil.putBool(_spKeyIsCodePulang, false);
             SpUtil.putBool(_spKeyIsPulangCepat, false);
             SpUtil.putBool(_spKeyIsIDLK, true);
          }
          // ... dll
        } else {
          SpUtil.putString(_spKeyStatusIdlk, '-');
          developer.log('Failed to load data _checkIdlkandPulangCepat (IDLK)');
        }
      }

      if (SpUtil.getBool(_spKeyIsPulangCepat) == true) {
        final responsePc = await http.get(
          Uri.parse('$url/api/cek-pulang-cepat/$idUser'),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        if (responsePc.statusCode == 200) {
          final data = jsonDecode(responsePc.body);
          SpUtil.putString(_spKeyStatusPC, data['data']);
          
          if (data['data'] == 'setujui') {
            // ... (Logika reset SpUtil Anda sudah benar)
             SpUtil.putBool(_spKeyIsCodeMasuk, false);
             SpUtil.putBool(_spKeyIsCodePulang, false);
             SpUtil.putBool(_spKeyIsPulangCepat, false);
             SpUtil.putBool(_spKeyIsIDLK, false);
             SpUtil.putString(_spKeyStatusIdlk, '-');

            // Update notifiers
            _isCodeMasukNotifier.value = false;
            _isCodePulangNotifier.value = false;
            _isPulangCepatNotifier.value = false;
            _isIDLKNotifier.value = false;
          } else if (data['data'] == 'tolak') {
            _isPulangCepatNotifier.value = false;
             SpUtil.putBool(_spKeyIsPulangCepat, false); // Tambahan
          }
          // 'pending' tidak melakukan apa-apa
        }
      }
    } catch (error) {
      developer.log('Error _checkIdlkandPulangCepat: $error');
    }
  }

  Future<void> _fetchNotif() async {
    if (idUser == null || idUser!.isEmpty || url == null || url!.isEmpty) {
      developer.log('Error _fetchNotif: idUser or url is empty');
      return;
    }

    try {
      final responseIzin = await http.get(
        Uri.parse('$url/api/notif/get-notif-count/$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (responseIzin.statusCode == 200) {
        final data = jsonDecode(responseIzin.body);
        _notifNotifier.value = data["tot_Notif"].toString();
      } else {
        developer.log('Failed to load data _fetchNotif');
      }
    } catch (error) {
      developer.log('Error _fetchNotif: $error');
    }
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    _getCurrentTime();
    await _initNetworkInfo();
    await _fetchNotif();
    // _isLoadingNotifier.value = false; // Variabel ini sudah dihapus
  }

  // =======================================================================
  // ⚙️ Logika Absensi (Handlers)
  // =======================================================================

  /// Menampilkan dialog konfirmasi sederhana.
  Future<bool?> _showConfirmationDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 15)),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Ya', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Batal', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
  }

  /// Memeriksa apakah WiFi saat ini ada di daftar putih (whitelist).
  bool _isWifiWhitelisted(String currentWifiName, String currentBSSID) {
    String connectedSSID = currentWifiName.replaceAll('"', '');
    var listWifiString = SpUtil.getString(_spKeyWifiData);
    if (listWifiString == null || listWifiString.isEmpty) {
      return false; // Tidak ada data WiFi tersimpan
    }

    try {
      List<dynamic> listWifi = jsonDecode(listWifiString);
      return listWifi.any(
          (wifi) => wifi['SSID'] == connectedSSID && wifi['BSSID'] == currentBSSID);
    } catch (e) {
      developer.log("Error parsing wifi data: $e");
      return false;
    }
  }

  /// Memvalidasi waktu shift untuk tipe user '1'.
  Map<String, dynamic> _checkShiftTime() {
    String? shiftDataString = SpUtil.getString(_spKeyShiftData);
    if (shiftDataString == null || shiftDataString.isEmpty) {
      return {'allowed': false, 'message': 'Jam shift tidak ditemukan.'};
    }

    try {
      List<dynamic> shifts = jsonDecode(shiftDataString);
      DateTime now = DateTime.now();
      Map? activeShift = _findActiveShiftForAttendance(shifts, now);

      if (activeShift == null) {
        return {'allowed': false, 'message': 'Tidak ada shift aktif saat ini.'};
      }

      final tglAwal = DateTime.parse(activeShift['tgl_awal']);
      final tglAkhir = DateTime.parse(activeShift['tgl_akhir']);
      final jamMulaiParts = (activeShift['jam_mulai'] as String).split(':');
      final jamSelesaiParts = (activeShift['jam_selesai'] as String).split(':');

      final shiftStart = DateTime(tglAwal.year, tglAwal.month, tglAwal.day, int.parse(jamMulaiParts[0]), int.parse(jamMulaiParts[1]));
      final shiftEnd = DateTime(tglAkhir.year, tglAkhir.month, tglAkhir.day, int.parse(jamSelesaiParts[0]), int.parse(jamSelesaiParts[1]));
      final jamBukaAbsen = shiftStart.subtract(const Duration(hours: 5));
      final reportDeadline = shiftEnd.add(const Duration(hours: 8));

      if (now.isAfter(jamBukaAbsen) && now.isBefore(shiftEnd)) {
        return {'allowed': true, 'message': ''};
      } else if (now.isBefore(jamBukaAbsen)) {
        String jamBukaAbsenStr = DateFormat('HH:mm').format(jamBukaAbsen);
        String jamSelesaiStr = DateFormat('HH:mm').format(shiftEnd);
        return {'allowed': false, 'message': 'Waktu absen belum tersedia. Mulai $jamBukaAbsenStr - $jamSelesaiStr.'};
      } else if (now.isBefore(reportDeadline)) {
        return {'allowed': false, 'message': 'Waktu absen sudah berakhir. Laporan harian hingga ${DateFormat('HH:mm').format(reportDeadline)}.'};
      } else {
        return {'allowed': false, 'message': 'Waktu absen & laporan sudah berakhir.'};
      }
    } catch (e) {
      developer.log('Error parsing shift data: $e');
      return {'allowed': false, 'message': 'Error data shift.'};
    }
  }
  
  /// Helper function dari logika shift Anda
  Map? _findActiveShiftForAttendance(List shifts, DateTime now) {
      for (final shift in shifts) {
        final tglAwal = DateTime.parse(shift['tgl_awal']);
        final tglAkhir = DateTime.parse(shift['tgl_akhir']);
        final jamMulaiParts = (shift['jam_mulai'] as String).split(':');
        final jamSelesaiParts = (shift['jam_selesai'] as String).split(':');

        final shiftStart = DateTime(tglAwal.year, tglAwal.month, tglAwal.day, int.parse(jamMulaiParts[0]), int.parse(jamMulaiParts[1]));
        final shiftEnd = DateTime(tglAkhir.year, tglAkhir.month, tglAkhir.day, int.parse(jamSelesaiParts[0]), int.parse(jamSelesaiParts[1]));
        
        // Toleransi: 5 jam sebelum shift mulai sampai 8 jam setelah shift selesai
        final startTolerance = shiftStart.subtract(const Duration(hours: 5));
        final endTolerance = shiftEnd.add(const Duration(hours: 8));

        if (now.isAfter(startTolerance) && now.isBefore(endTolerance)) {
          return shift;
        }
      }
      return null;
  }

  /// Handler utama untuk logika "Absen Masuk".
  Future<void> _handleAbsenMasuk() async {
    _loadingStateNotifier.value = AbsenLoadingState.masuk;
    try {
      // 1. Refresh & validasi network info
      await _initNetworkInfo();
      // final currentWifiName = 'IKP KOMINFO';
      // final currentBSSID = 'e6:63:da:a1:9d:6b';
      final currentWifiName = _wifiNameNotifier.value;
      final currentBSSID = wifiBSSID;

      if (currentWifiName == null || currentBSSID == null ||
          currentWifiName.isEmpty || currentBSSID.isEmpty) {
        if (mounted) Alert.alertwarning(context, 'Silahkan sambungkan ke WiFi!');
        _loadingStateNotifier.value = AbsenLoadingState.none;
        return;
      }

      // 2. Cek Wi-Fi whitelist
      if (!_isWifiWhitelisted(currentWifiName, currentBSSID)) {
        // print({'ssid': currentWifiName, 'bssid': currentBSSID});
          if (mounted) Alert.alertwarning(context, 'SSID tidak ditemukan dalam daftar WiFi!');
          _loadingStateNotifier.value = AbsenLoadingState.none;
          return;
      }

      // 3. Cek Waktu Shift (jika tipe user "1")
      if (SpUtil.getString(_spKeyIdType) == '1') {
        final shiftCheck = _checkShiftTime();
        if (!shiftCheck['allowed']) {
          if (mounted) Alert.alertwarning(context, shiftCheck['message']);
          _loadingStateNotifier.value = AbsenLoadingState.none;
          return;
        }
      }

      // 4. Lolos pengecekan, lakukan API call
      await _apiAbsenMasuk(currentWifiName, currentBSSID);

    } catch (e) {
      if (mounted) Alert.alerterror(context, 'Gagal mengambil absen! ${e.toString()}');
    } finally {
      if (mounted) {
          _loadingStateNotifier.value = AbsenLoadingState.none;
      }
    }
  }

  /// Handler utama untuk logika "Absen Pulang".
  Future<void> _handleAbsenPulang() async {
    _loadingStateNotifier.value = AbsenLoadingState.pulang;

    try {
      // 1. Refresh network info
      await _initNetworkInfo();
      final currentWifiName = _wifiNameNotifier.value;
      final currentBSSID = wifiBSSID;

      // 2. Cek "Pulang Cepat" pending
      if (SpUtil.getBool(_spKeyIsPulangCepat) == true &&
          SpUtil.getString(_spKeyStatusIdlk) == '-' &&
          SpUtil.getString(_spKeyStatusPC) == 'pending') {
        if (mounted) {
          Alert.alertwarning(context, 'Sedang mengajukan Pulang Cepat. Hapus pengajuan untuk absen pulang.');
        }
        _loadingStateNotifier.value = AbsenLoadingState.none;
        return;
      }

      // 3. Cek "Belum Absen Masuk"
      if (SpUtil.getBool(_spKeyIsCodeMasuk) == false &&
          SpUtil.getString(_spKeyStatusIdlk) == '-') {
        if (mounted) {
            Alert.alertwarning(context, "Belum mengambil absen masuk!");
        }
          _loadingStateNotifier.value = AbsenLoadingState.none;
        return;
      }

      // 4. Handle IDLK (Disetujui)
      if (SpUtil.getString(_spKeyStatusIdlk) == 'setujui') {
        if (mounted) {
            final bool? confirmed = await _showConfirmationDialog('Yakin ingin absen pulang (IDLK)?');
            if (confirmed == true) {
                await _apiAbsenPulang(isIDLK: true);
            }
        }
        _loadingStateNotifier.value = AbsenLoadingState.none;
        return;
      }

      // 5. Handle Normal Pulang (Validasi WiFi)
      if (currentWifiName == null || currentBSSID == null ||
          currentWifiName.isEmpty || currentBSSID.isEmpty) {
          if (mounted) Alert.alertwarning(context, 'Silahkan sambungkan ke WiFi!');
          _loadingStateNotifier.value = AbsenLoadingState.none;
          return;
      }

      if (!_isWifiWhitelisted(currentWifiName, currentBSSID)) {
          if (mounted) Alert.alertwarning(context, 'SSID tidak ditemukan dalam daftar WiFi!');
          _loadingStateNotifier.value = AbsenLoadingState.none;
          return;
      }

      // 6. Lolos pengecekan, konfirmasi & panggil API
      if (mounted) {
          final bool? confirmed = await _showConfirmationDialog('Yakin ingin absen pulang?');
          if (confirmed == true) {
              await _apiAbsenPulang(
                  isIDLK: false,
                  wifiName: currentWifiName,
                  wifiBSSID: currentBSSID);
          }
      }

    } catch (e) {
      if (mounted) Alert.alerterror(context, 'Gagal mengambil absen pulang! ${e.toString()}');
    } finally {
      if (mounted) {
        _loadingStateNotifier.value = AbsenLoadingState.none;
      }
    }
  }


  // =======================================================================
  // 🚀 Fungsi Core API (Isolasi)
  // =======================================================================

  /// Fungsi terisolasi untuk API call "absenMasuk".
  Future<void> _apiAbsenMasuk(String connectedSSID, String connectedBSSID) async {
    var datamasuk = {
      'id_user': idUser,
      'id_admin_instansi': idAdmin,
      'nama_lengkap': nama,
      'username': SpUtil.getString(_spKeyUsername),
      'instansi': SpUtil.getString(_spKeyIdInstansi),
      'SSID': connectedSSID.replaceAll('"', ''),
      'BSSID': connectedBSSID,
      'versi': _versiApp,
      'deviceId': SpUtil.getString(StorageKeys.deviceId),
      'id_type': SpUtil.getString(_spKeyIdType),
    };


    http.Response absenMasuk = await http
        .post(
          Uri.parse('$url/api/masuk'),
          body: datamasuk,
        )
        .timeout(const Duration(seconds: 30));

    await Future.delayed(const Duration(seconds: 2)); // Ada di kode asli Anda

    if (!mounted) return;

    if (absenMasuk.statusCode == 200) {
      final data = jsonDecode(absenMasuk.body);
      String message = data["message"] as String;
      String dataCode = data["code"] as String;

      if (dataCode == "wifi" || dataCode == "versi_app" || dataCode == "unknown") {
        Alert.alertwarning(context, message);
      } else if (dataCode == "1" || dataCode == "2") {
        String waktuJson = data['waktu'];
        DateTime waktuText = DateTime.parse(waktuJson);
        jamMasuk = DateFormat('HH:mm').format(waktuText);

        SpUtil.putString(_spKeySavedDate, DateFormat('yyyy-MM-dd').format(waktuText));
        SpUtil.putString(_spKeyJamMasuk, jamMasuk!);
        SpUtil.putBool(_spKeyIsCodeMasuk, true);

        Alert.alertsuccess(context, message);
        _isCodeMasukNotifier.value = true;
      } else {
        // Termasuk code "5" atau lainnya
        Alert.alertinfo(context, message);
        _isCodeMasukNotifier.value = false;
      }
    } else {
      throw Exception('Kesalahan HTTP: ${absenMasuk.statusCode}');
    }
  }

  /// Fungsi terisolasi untuk API call "absenPulang".
  Future<void> _apiAbsenPulang({
    required bool isIDLK,
    String? wifiName,
    String? wifiBSSID,
  }) async {
    var datapulang = {
      'id_user': idUser,
      'versi': _versiApp,
      'deviceId': SpUtil.getString(StorageKeys.deviceId),
      'id_type': SpUtil.getString(_spKeyIdType),
      'SSID_pulang': isIDLK ? 'IDLK' : wifiName?.replaceAll('"', ''),
      'BSSID_pulang': isIDLK ? 'IDLK' : wifiBSSID,
    };

    http.Response absenPulang = await http.put(
      Uri.parse('$url/api/pulang/$idUser'),
      body: jsonEncode(datapulang), // Kode asli pakai jsonEncode
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ).timeout(const Duration(seconds: 30));

    if (!mounted) return;

    final data = jsonDecode(absenPulang.body);
    String message = data["message"] as String;
    String dataCode = data["code"] as String;

    if (absenPulang.statusCode == 200) {
      code = data['code']?.toString();

      if (dataCode == "1") {
        SpUtil.putString(_spKeyCodePulang, code!);
        String waktuJson = data['waktu'];
        DateTime waktuText = DateTime.parse(waktuJson);
        jamPulang = DateFormat('HH:mm').format(waktuText);
        SpUtil.putString(_spKeyJamPulang, jamPulang!);

        // Reset semua status
        SpUtil.putString(_spKeyStatusPC, '-');
        SpUtil.putString(_spKeyStatusIdlk, '-');
        SpUtil.putBool(_spKeyIsPulangCepat, false);
        SpUtil.putBool(_spKeyIsIDLK, false);
        SpUtil.putInt(_spKeyIdlkInt, 0); 
        SpUtil.putBool(_spKeyIsCodePulang, true);

        if (mounted) {
          Alert.alertsuccess(context, message);
          _isCodePulangNotifier.value = true;
          _isPulangCepatNotifier.value = false;
          _isIDLKNotifier.value = false;
        }
      } else if (dataCode == "5") {
        Alert.alertinfo(context, message);
        _isCodeMasukNotifier.value = false; // Ada di kode asli
      } else {
        Alert.alertwarning(context, message);
      }
    } else {
      Alert.alertwarning(context, 'Tidak dapat terhubung ke server');
    }
  }


  // =======================================================================
  // 📱 Build Method (UI)
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          const Header(), // Asumsi Header adalah widget
          Column(
            children: [
              SizedBox(height: size.height * 0.15),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Skeletonizer(
                    enabled: _enabled,
                    enableSwitchAnimation: true,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Fitur(),
                        // Widget Status WiFi
                        _buildWifiStatus(),
                        // Widget Jam dan Tanggal
                        _buildTimeAndDate(),
                        const SizedBox(height: 20),
                        // Tombol Absensi
                        _buildAttendanceButtons(),
                        // Widget Kondisional (Pulang Cepat / IDLK)
                        _buildConditionalStatus(),
                      ],
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

  /// Widget untuk menampilkan status WiFi.
  Widget _buildWifiStatus() {
    return ValueListenableBuilder<String?>(
      valueListenable: _wifiNameNotifier,
      builder: (context, wifiNameValue, child) {
        final namaSSID = (wifiNameValue?.isNotEmpty ?? false)
            ? wifiNameValue!.replaceAll('"', '')
            : 'Wifi tidak terhubung';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color.fromARGB(255, 221, 235, 235)),
            color: const Color.fromARGB(255, 240, 255, 255),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromARGB(255, 226, 226, 226),
                  spreadRadius: 1,
                  blurRadius: 1)
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Skeleton.replace(
                    child: Text(
                      namaSSID,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 255, 31, 31)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget untuk menampilkan jam dan tanggal.
  Widget _buildTimeAndDate() {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      width: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                // Tampilan Jam
                ValueListenableBuilder<String>(
                  valueListenable: _jamSekarangNotifier,
                  builder: (context, jamValue, child) {
                    return Text(
                      jamValue,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 14, 60, 129),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                // Tampilan Tanggal
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'id')
                      .format(DateTime.now()),
                  style: const TextStyle(fontSize: 25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk membangun tombol Absen Masuk dan Pulang.
  Widget _buildAttendanceButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isCodeMasukNotifier,
      builder: (context, isCodeMasukValue, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isCodePulangNotifier,
          builder: (context, isCodePulangValue, child) {
            return ValueListenableBuilder<AbsenLoadingState>(
              valueListenable: _loadingStateNotifier,
              builder: (context, loadingState, child) {
                final bool isLoading = loadingState != AbsenLoadingState.none;
                final bool isMasukLoading = loadingState == AbsenLoadingState.masuk;
                final bool isPulangLoading = loadingState == AbsenLoadingState.pulang;

                return Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Row(
                    children: [
                      // Tombol Masuk
                      _buildCheckInButton(isCodeMasukValue, isLoading, isMasukLoading),
                      const Spacer(),
                      // Tombol Pulang
                      _buildCheckOutButton(isCodePulangValue, isLoading, isPulangLoading),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Widget Tombol Masuk
  Widget _buildCheckInButton(bool isCodeMasuk, bool isLoading, bool isMasukLoading) {
    return Column(
      children: [
        isCodeMasuk
            ? Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 173, 218, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      SpUtil.getString(_spKeyJamMasuk) ?? "--:--",
                      style: const TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 2, 53, 95)),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              )
            : GestureDetector(
                onTap: isLoading ? null : _handleAbsenMasuk,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isMasukLoading
                        ? const SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(child: CircularProgressIndicator()))
                        : Skeletonizer(
                            enabled: _enabled,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Skeleton.replace(
                                    child: Image.asset('assets/new/masuk.png'),
                                  ),
                                ),
                                const Text(
                                  "Masuk",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                    // Placeholder agar tinggi konsisten
                    if (!isMasukLoading) const SizedBox(height: 25),
                  ],
                ),
              ),
      ],
    );
  }

  /// Widget Tombol Pulang
  Widget _buildCheckOutButton(bool isCodePulang, bool isLoading, bool isPulangLoading) {
    return Column(
      children: [
        isCodePulang
            ? Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 173, 218, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      SpUtil.getString(_spKeyJamPulang) ?? "--:--",
                      style: const TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 2, 53, 95)),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              )
            : GestureDetector(
                onTap: isLoading ? null : _handleAbsenPulang,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isPulangLoading
                        ? const SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(child: CircularProgressIndicator()))
                        : Skeletonizer(
                            enabled: _enabled,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Skeleton.replace(
                                    child: Image.asset('assets/new/pulang.png'),
                                  ),
                                ),
                                Text(
                                  SpUtil.getString(_spKeyStatusIdlk) != 'setujui'
                                      ? "Pulang"
                                      : "IDLK",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                    // Placeholder agar tinggi konsisten
                    if (!isPulangLoading) const SizedBox(height: 25),
                  ],
                ),
              ),
      ],
    );
  }

  /// Widget untuk status kondisional (Pulang Cepat, IDLK).
  Widget _buildConditionalStatus() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPulangCepatNotifier,
      builder: (context, isPulangCepatValue, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isIDLKNotifier,
          builder: (context, isIDLKValue, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isCodeMasukNotifier,
              builder: (context, isCodeMasukValue, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isCodePulangNotifier,
                  builder: (context, isCodePulangValue, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildConditionalWidgets(
                          context,
                          isPulangCepatValue,
                          isIDLKValue,
                          isCodeMasukValue,
                          isCodePulangValue,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Logika untuk menampilkan widget kondisional berdasarkan status.
  Widget _buildConditionalWidgets(
    BuildContext context,
    bool isPulangCepat,
    bool isIDLK,
    bool isCodeMasuk,
    bool isCodePulang,
  ) {
    final statusPC = SpUtil.getString(_spKeyStatusPC);
    final statusIDLK = SpUtil.getString(_spKeyStatusIdlk);

    if (statusIDLK == 'setujui') {
      return const Card(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'IDLK sudah di setujui \nsilahkan mengambil absen pulang',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } 
    
    if (isPulangCepat || isIDLK) {
      // Ini mencakup status 'pending' untuk IDLK atau PulangCepat
      return ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(initialIndex: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 173, 218, 255),
        ),
        child: const Text(
          'Status Pengajuan',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 162, 255),
          ),
        ),
      );
    } 
    
    if (statusPC == 'setujui') {
      return const Card(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Pulang Cepat sudah di setujui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } 
    
    if (statusPC == 'tolak') {
      return const Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Pulang Cepat ditolak \n Tetap gunakan absen pulang!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } 
    
    if (isCodeMasuk && !isCodePulang) {
      // Tombol Pulang Cepat hanya muncul jika sudah absen masuk
      // dan belum absen pulang, dan tidak sedang mengajukan apapun
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PulangCepat(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Pulang Cepat',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } 
    
    // Default: tidak menampilkan apa-apa
    return const SizedBox.shrink();
  }
}