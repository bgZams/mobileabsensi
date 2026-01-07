import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/services/get_uuid.dart';
import 'package:sp_util/sp_util.dart';

class AppConstants {
  // URL untuk Login (selalu tetap)
  static const String simpelBaseUrl = 'https://simpel.pasamanbaratkab.go.id/api_android/simaya';

  // URL Dinamis untuk Absensi (berubah sesuai id_server)
  static String getLocalBaseUrl(String idServer) {
    return 'http://mobileabsensi$idServer.pasamanbaratkab.go.id/api_android_v2';
  }

  static const String loginEndpoint = '$simpelBaseUrl/api/model_login2.php';
  static const String pegawaiEndpoint = '$simpelBaseUrl/getByIdUser.php';

  // Path endpoint lokal
  static const String pathDevice = '/api/getDevice';
  static const String pathDeviceCheck = '/api/cek-device';
  static const String pathWifi = '/api/wifi';
  static const String pathShift = '/api/jam-kerja';
}

class StorageKeys {
  static const String isLogin = 'is_login';
  static const String deviceId = 'device_id';
  static const String systemVersion = 'system_version';
  static const String idServer = 'id_server';
  static const String idUser = 'id_user';
  static const String idType = 'id_type';
  static const String idInstansi = 'id_instansi';
  static const String idGroups = 'id_groups';
  static const String idUserPimpinan = 'id_user_pimpinan';
  static const String idAdminInstansi = 'id_admin_instansi';
  static const String idPimpinan = 'id_pimpinan';
  static const String username = 'username';
  static const String usernameAdmin = 'username_admin';
  static const String namaLengkap = 'nama_lengkap';
  static const String namaInstansi = 'nama_instansi';
  static const String namaAtasan = 'nama_atasan';
  static const String nipAtasan = 'nip_atasan';
  static const String jabatanAtasan = 'jabatan_atasan';
  static const String url = 'url';
  static const String wifiData = 'wifi_data';
  static const String shiftData = 'shift_data';
}

const Color textWhiteGrey = Color(0xFFF1F1F1);
const Color textGrey = Color(0xFFAAAAAA);
const TextStyle heading6 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

class ApiService {
  final http.Client _client = http.Client();
  final Duration _timeoutDuration = const Duration(seconds: 15);

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _formHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };

  // 1. Login ke Simpel (Mendapatkan id_server dari sini)
  Future<Map<String, dynamic>> login(String username, String password, String deviceId) async {
    final response = await _client.post(
      Uri.parse(AppConstants.loginEndpoint),
      headers: _formHeaders,
      body: {
        'username': username,
        'password': password,
        'device_id': deviceId,
        'system_version': SpUtil.getString(StorageKeys.systemVersion) ?? '',
      },
    ).timeout(_timeoutDuration);

    return json.decode(response.body);
  }

  // 2. Menggunakan idServer yang didapat dari Login untuk request selanjutnya
  Future<Map<String, dynamic>> getDevice(Map<String, dynamic> body, String idServer) async {
    String baseUrl = AppConstants.getLocalBaseUrl(idServer);

    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.pathDevice}'),
          headers: _jsonHeaders,
          body: json.encode(body),
        )
        .timeout(_timeoutDuration);

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getWifiData(String usernameAdmin) async {
    String idServer = SpUtil.getString(StorageKeys.idServer) ?? '1';
    String baseUrl = AppConstants.getLocalBaseUrl(idServer);

    final response = await _client.get(
      Uri.parse('$baseUrl${AppConstants.pathWifi}/$usernameAdmin'),
      headers: _jsonHeaders,
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getShiftData(String idUser) async {
    String idServer = SpUtil.getString(StorageKeys.idServer) ?? '1';
    String baseUrl = AppConstants.getLocalBaseUrl(idServer);

    final response = await _client.get(
      Uri.parse('$baseUrl${AppConstants.pathShift}/$idUser'),
      headers: _jsonHeaders,
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getPegawaiData(String idUser) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.pegawaiEndpoint}?id_user=$idUser'),
      headers: _jsonHeaders,
    );
    return json.decode(response.body);
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final ApiService _apiService = ApiService();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _isDeviceInfoReady = false;
  bool _deviceInfoError = false;
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  Timer? _deviceInfoRetryTimer;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatusAndInitialize();
    });
  }

  @override
  void dispose() {
    _deviceInfoRetryTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndInitialize() async {
    if (SpUtil.getBool(StorageKeys.isLogin) == true) {
      _navigateToHome();
    } else {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      await _initializeDeviceInfo();
      if (mounted) {
        setState(() {
          _isDeviceInfoReady = true;
          _deviceInfoError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize device info: $e");
      }
      if (mounted) {
        setState(() {
          _deviceInfoError = true;
        });
      }

      _deviceInfoRetryTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDeviceInfoReady) {
          _initializeApp();
        }
      });
    }
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      String? id = await DeviceUtil.getAndroidId();

      if (id != null) {
        await SpUtil.putString(StorageKeys.deviceId, id);
        // print("✅ Device ID berhasil disimpan otomatis: $id");
      } else {
        // print("⚠️ Device ID null");
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        String systemVersion = androidInfo.version.release;
        await SpUtil.putString(StorageKeys.systemVersion, systemVersion);
      } else {
        await SpUtil.putString(StorageKeys.systemVersion, 'Unknown');
      }

      if (mounted) {
        setState(() {
          _isDeviceInfoReady = true;
          _deviceInfoError = false;
        });
      }
    } catch (e) {
      // print("⚠️ Gagal init device info: $e");
      await _setFallbackDeviceInfo();
    }
  }

  Future<void> _setFallbackDeviceInfo() async {
    final fallbackId = 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    await SpUtil.putString(StorageKeys.systemVersion, 'Unknown');

    if (mounted) {
      setState(() {
        _deviceData = {
          'Error': 'Using fallback device info',
          'id': fallbackId,
          'version.release': 'Unknown'
        };
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  Future<void> _startLoading() async {
    if (!_isDeviceInfoReady) {
      if (_deviceInfoError) {
        Alert.alerterror(context, 'Gagal mendapatkan informasi perangkat. Mohon restart aplikasi.');
      } else {
        Alert.alertwarning(context, 'Sedang memuat informasi perangkat, mohon tunggu...');
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String deviceId = SpUtil.getString(StorageKeys.deviceId) ?? ""; 
      await _login(_usernameController.text, _passwordController.text, deviceId);
    } catch (e) {
      if (kDebugMode) print("Login Error: $e");
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
        if (e is TimeoutException) {
          errorMessage = 'Timeout terhubung ke server.';
        } else if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
          errorMessage = 'Tidak dapat terhubung ke server.';
        }
        Alert.alerterror(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login(String username, String password, String deviceId) async {
    if (deviceId == null || deviceId.isEmpty) {
      Alert.alerterror(context, 'Informasi perangkat tidak valid. Mohon restart aplikasi.');
      return;
    }

    // --- STEP 1: LOGIN ---
    final simpel = await _apiService.login(username, password, deviceId);

    if (mounted && simpel["success"] == 1) {
      // Masuk ke handle success dengan membawa data login (yang berisi id_server)
      await _handleLoginSuccess(simpel, username, deviceId);
    } else if (mounted) {
      Alert.alertwarning(context, simpel["message"] ?? 'Username atau password salah.');
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> simpel, String username, String deviceId) async {
    // --- STEP 2: AMBIL ID SERVER DARI RESPON LOGIN ---
    // Menggunakan safe call agar tidak crash jika null, default ke '1'
    String idServer = simpel['id_server']?.toString() ?? '1';
    // print('idServer: $idServer');
    // Simpan id_server ke penyimpanan lokal
    await SpUtil.putString(StorageKeys.idServer, idServer);

    if (simpel["id_groups"] == 2) {
      await _syncAndStoreUserData(simpel);
      _navigateToHome();
      return;
    }

    if (mounted && simpel['success'] == 1) {
      if (simpel["id_user"] != SpUtil.getString(StorageKeys.idUser)) {
        SpUtil.clear();
        await _initializeApp();
        // Penting: Simpan ulang idServer karena clear() menghapusnya
        await SpUtil.putString(StorageKeys.idServer, idServer);
      }

      // --- STEP 3: GUNAKAN ID SERVER UNTUK GET DEVICE ---
      final deviceData = await _apiService.getDevice({
        'id_user': simpel['id_user'].toString(),
        'device_id': SpUtil.getString('device_id'),
        'username': simpel['username'],
        'versiApp': SpUtil.getString(StorageKeys.systemVersion),
        'version_apk': '1.0.11',
        'id_type': simpel['id_type'],
      }, idServer);
      if (mounted && deviceData['status'] == true) {
        await _syncAndStoreUserData(simpel);
        _navigateToHome();
      } else if (mounted) {
        Alert.alertwarning(context, deviceData["message"]);
      }
    } else {
      Alert.alertwarning(context, simpel["message"]);
    }
  }

  Future<void> _syncAndStoreUserData(Map<String, dynamic> body) async {
    try {
      final responses = await Future.wait([
        _apiService.getWifiData(body['username_admin']),
        _apiService.getShiftData(body['id_user']),
        _apiService.getPegawaiData(body['id_user']),
      ]);

      final wifiData = responses[0];
      final shiftData = responses[1];
      final pegawaiData = responses[2];

      if (wifiData['data'] != null) {
        SpUtil.putString(StorageKeys.wifiData, json.encode(wifiData['data']));
      } else if (mounted) {
        Alert.alertwarning(context, 'Gagal menyingkronkan data wifi.');
      }

      if (shiftData['data'] != null) {
        SpUtil.putString(StorageKeys.shiftData, json.encode(shiftData['data']));
      } else if (mounted) {
        Alert.alertwarning(context, 'Gagal menyingkronkan data jam kerja.');
      }

      if (pegawaiData['data'] != null && (pegawaiData['data'] as List).isNotEmpty) {
        _storeUserData(pegawaiData['data'][0]);
      } else if (mounted) {
        Alert.alertwarning(context, 'Gagal menyingkronkan data pegawai.');
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, 'Gagal menyingkronkan data pengguna');
      }
      if (kDebugMode) {
        print(Exception(e));
      }
      rethrow;
    }
  }

  void _storeUserData(Map<String, dynamic> userData) {
    // Ambil id_server dari data user untuk disimpan ulang (double check)
    String idServer = userData['id_server']?.toString() ?? SpUtil.getString(StorageKeys.idServer) ?? '1';

    SpUtil.putString(StorageKeys.idServer, idServer);
    SpUtil.putString(StorageKeys.idUser, userData['id_user']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idType, userData['id_type']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idInstansi, userData['id_instansi']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idGroups, userData['id_groups']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idUserPimpinan, userData['id_user_parent']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idAdminInstansi, userData['id_admin_instansi']?.toString() ?? '');
    SpUtil.putString(StorageKeys.idPimpinan, userData['id_pimpinan']?.toString() ?? '');
    SpUtil.putString(StorageKeys.username, (userData['username'] ?? '').replaceAll('"', ''));
    SpUtil.putString(StorageKeys.usernameAdmin, (userData['username_admin'] ?? '').replaceAll('"', ''));
    SpUtil.putString(StorageKeys.namaLengkap, (userData['nama_lengkap'] ?? '').replaceAll('"', ''));
    SpUtil.putString(StorageKeys.namaInstansi, userData['nama_instansi']?.toString() ?? '');
    SpUtil.putString(StorageKeys.namaAtasan, userData['nama_atasan']?.toString() ?? '');
    SpUtil.putString(StorageKeys.nipAtasan, userData['nip_atasan']?.toString() ?? '');
    SpUtil.putString(StorageKeys.jabatanAtasan, userData['jabatan_atasan']?.toString() ?? '');

    // Simpan URL yang sudah terbentuk dinamis
    SpUtil.putString(StorageKeys.url, AppConstants.getLocalBaseUrl(idServer));
  }

  void _navigateToHome() {
    if (!mounted) return;

    String? idGroups = SpUtil.getString(StorageKeys.idGroups);

    if (idGroups == "3" || idGroups == "5") {
      SpUtil.putBool(StorageKeys.isLogin, true);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } else if (idGroups == "2") {
      SpUtil.putBool(StorageKeys.isLogin, true);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
        (route) => false,
      );
    } else {
      SpUtil.clear();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Perhitungan Scaling yang konsisten
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    const double referenceWidth = 381.0;
    final double scaleFactor = screenWidth / referenceWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      // Penting: Memastikan body bergeser ke atas saat keyboard muncul
      resizeToAvoidBottomInset: true,
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/new/login.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Mencegah error overflow pixel saat konten melebihi tinggi layar
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50 * scaleFactor),

                  // Header Logo
                  SizedBox(
                    width: 230 * scaleFactor,
                    child: Image.asset(
                      "assets/new/login-header.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: 60 * scaleFactor),

                  Text(
                    'Hi, Selamat Datang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 25 * scaleFactor),

                  // Form Section
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          hintText: 'Username',
                          isPassword: false,
                          scaleFactor: scaleFactor,
                        ),
                        SizedBox(height: 20 * scaleFactor),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          isPassword: true,
                          scaleFactor: scaleFactor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30 * scaleFactor),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isDeviceInfoReady) ? null : _startLoading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(246, 54, 51, 100),
                        padding: EdgeInsets.symmetric(vertical: 18 * scaleFactor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * scaleFactor),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20 * scaleFactor,
                              width: 20 * scaleFactor,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              !_isDeviceInfoReady ? 'Memuat...' : 'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0 * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Version Info
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40 * scaleFactor),
                    child: Center(
                      child: Text(
                        'App version 1.0.11',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                          fontSize: 12 * scaleFactor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isPassword,
    required double scaleFactor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_passwordVisible,
      style: TextStyle(fontSize: 15 * scaleFactor, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F0F5), // Gunakan variabel textWhiteGrey Anda di sini
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14 * scaleFactor),

        contentPadding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor, vertical: 18 * scaleFactor),

        // Border Normal
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25 * scaleFactor),
          borderSide: BorderSide.none,
        ),

        // Border & Style saat Error muncul
        errorStyle: TextStyle(
          color: Colors.orangeAccent, // Warna terang agar terlihat di background gelap
          fontSize: 12 * scaleFactor,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25 * scaleFactor),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25 * scaleFactor),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20 * scaleFactor,
                  color: Colors.grey,
                ),
                onPressed: _togglePasswordVisibility,
              )
            : null,
      ),
      // Validator yang sudah dibersihkan dari spasi liar
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Mohon masukkan ${hintText.trim()}';
        }
        return null;
      },
    );
  }
}
