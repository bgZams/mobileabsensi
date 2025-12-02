import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Use 'as http' for clarity
import 'package:mobileabsensi/services/alert.dart';
import 'package:mobileabsensi/services/get_uuid.dart';
import 'package:sp_util/sp_util.dart';

// --- CONSTANTS ---
// Moved all hardcoded strings to central classes for easy maintenance.

class AppConstants {
  // Base URLs
  static const String simpelBaseUrl = 'https://simpel.pasamanbaratkab.go.id/api_android/simaya';
  static const String localApiBaseUrl = 'http://mobileabsensi1.pasamanbaratkab.go.id/api_android_v2';
  // static const String localApiBaseUrl = 'http://172.25.88.15:8000';

  // API Endpoints
  static const String loginEndpoint = '$simpelBaseUrl/api/model_login2.php';
  static const String pegawaiEndpoint = '$simpelBaseUrl/getByIdUser.php';
  
  static const String deviceEndpoint = '$localApiBaseUrl/api/getDevice';
  static const String deviceCheckEndpoint = '$localApiBaseUrl/api/cek-device';
  static const String wifiEndpoint = '$localApiBaseUrl/api/wifi';
  static const String shiftEndpoint = '$localApiBaseUrl/api/jam-kerja';
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

// --- STYLES ---
const Color textWhiteGrey = Color(0xFFF1F1F1);
const Color textGrey = Color(0xFFAAAAAA);
const TextStyle heading6 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

// --- API SERVICE ---
// All network logic is now in one place.
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
  Future<Map<String, dynamic>> getDevice(Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(AppConstants.deviceEndpoint),
      headers: _jsonHeaders,
      body: json.encode(body),
    ).timeout(_timeoutDuration);

    return json.decode(response.body);
  } 

  Future<Map<String, dynamic>> getWifiData(String usernameAdmin) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.wifiEndpoint}/$usernameAdmin'),
      headers: _jsonHeaders,
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getShiftData(String idUser) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.shiftEndpoint}/$idUser'),
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

// --- LOGIN WIDGET ---
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  // Services
  final ApiService _apiService = ApiService();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // State
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _isDeviceInfoReady = false;
  bool _deviceInfoError = false;
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  Timer? _deviceInfoRetryTimer;

  // Form & Controllers
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

  /// Checks if user is already logged in. If so, navigates to dashboard.
  /// Otherwise, starts the app initialization.
  Future<void> _checkLoginStatusAndInitialize() async {
    if (SpUtil.getBool(StorageKeys.isLogin) == true) {
      _navigateToHome();
    } else {
      _initializeApp();
    }
  }

  /// Initializes device info with a retry mechanism.
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
      
      // Retry after 3 seconds if failed
      _deviceInfoRetryTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDeviceInfoReady) {
          _initializeApp(); // Retry initialization
        }
      });
    }
  }

  /// Fetches and stores platform-specific device information.
  Future<void> _initializeDeviceInfo() async {
    try {
      // 1. Ambil & Simpan Device ID (Menggunakan kode baru Anda)
      // Pastikan class DeviceUtil sudah di-import
      String? id = await DeviceUtil.getAndroidId();
      
      if (id != null) {
        // Gunakan StorageKeys.deviceId agar konsisten dengan bagian kode lain
        await SpUtil.putString(StorageKeys.deviceId, id);
        print("✅ Device ID berhasil disimpan otomatis: $id");
      } else {
        print("⚠️ Device ID null");
      }

      // 2. Ambil & Simpan System Version (PENTING: Ini bagian yang hilang di snippet baru Anda)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        String systemVersion = androidInfo.version.release;
        await SpUtil.putString(StorageKeys.systemVersion, systemVersion);
      } else {
        await SpUtil.putString(StorageKeys.systemVersion, 'Unknown');
      }

      // Update state agar tombol login menyala
      if (mounted) {
        setState(() {
            _isDeviceInfoReady = true;
            _deviceInfoError = false;
        });
      }

    } catch (e) {
      print("⚠️ Gagal init device info: $e");
      // Fallback jika error
      await _setFallbackDeviceInfo();
    }
  }

  /// Sets fallback device info if platform is not Android or an error occurs.
  Future<void> _setFallbackDeviceInfo() async {
    final fallbackId = 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    await SpUtil.putString(StorageKeys.systemVersion, 'Unknown');
    
    if(mounted) {
      setState(() {
        _deviceData = {
          'Error': 'Using fallback device info',
          'id': fallbackId,
          'version.release': 'Unknown'
        };
      });
    }
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      'version.release': build.version.release,
      'id': build.id,
      'androidId': build.id,
      'fingerprint': build.fingerprint,
      'model': build.model,
      'manufacturer': build.manufacturer,
    };
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  /// Starts the login process.
  Future<void> _startLoading() async { 
    // Check device info readiness
    if (!_isDeviceInfoReady) {
      if (_deviceInfoError) {
        Alert.alerterror(context, 'Gagal mendapatkan informasi perangkat. Mohon restart aplikasi.');
      } else {
        Alert.alertwarning(context, 'Sedang memuat informasi perangkat, mohon tunggu...');
      }
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var deviceId = SpUtil.getString('device_id');
      await _login(_usernameController.text, _passwordController.text, deviceId!);
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

  /// Handles the core login API call and response.
  Future<void> _login(String username, String password, String deviceId) async {
    if (deviceId == null || deviceId.isEmpty) {
      Alert.alerterror(context, 'Informasi perangkat tidak valid. Mohon restart aplikasi.');
      return;
    }

    final simpel = await _apiService.login(username, password, deviceId);

    if (mounted && simpel["success"] == 1) {
      if(simpel["id_admin_instansi"] == '4393'){
        await _handleLoginSuccess(simpel, username, deviceId);
      } else {
        Alert.alertwarning(context, 'Maaf, Anda bukan admin instansi yang diizinkan.');
      }
    } else if (mounted) {
      Alert.alertwarning(context, simpel["message"] ?? 'Username atau password salah.');
    }
  }

  /// Handles the logic *after* a successful login response is received.
  Future<void> _handleLoginSuccess(Map<String, dynamic> simpel, String username, String deviceId) async {
    SpUtil.putString(StorageKeys.idServer, simpel['id_server'].toString());
    // Group 2 (Admin) just syncs and navigates
    if (simpel["id_groups"] == 2) {
      await _syncAndStoreUserData(simpel);
      _navigateToHome();
      return;
    }
 
 

    if (mounted && simpel['success'] == 1) {
      if(simpel["id_user"] != SpUtil.getString(StorageKeys.idUser)){
        SpUtil.clear();
        await _initializeApp();
      }

      final deviceData = await _apiService.getDevice({
        'id_user': simpel['id_user'].toString(),
        'device_id': SpUtil.getString('device_id'),
        'username': simpel['username'],
        'versiApp': SpUtil.getString(StorageKeys.systemVersion),
        'id_type': simpel['id_type'],
      });

  

      if (mounted && deviceData['status'] == true) {
        await _syncAndStoreUserData(simpel);
        _navigateToHome();
      } else if (mounted) {
        print("X Login gagal - Device check failed: ${deviceData}");

        Alert.alertwarning(context, deviceData["message"]);
      }
    } else {
         Alert.alertwarning(context, simpel["message"]);
      
    }
  }

  /// Fetches and stores all necessary user data from multiple endpoints.
  Future<void> _syncAndStoreUserData(Map<String, dynamic> body) async {
    try {
      // Run data fetching in parallel
      final responses = await Future.wait([
        _apiService.getWifiData(body['username_admin']),
        _apiService.getShiftData(body['id_user']),
        _apiService.getPegawaiData(body['id_user']),
      ]);

      // Process responses
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

  /// Saves user data to SharedPreferences.
  void _storeUserData(Map<String, dynamic> userData) {
    SpUtil.putString(StorageKeys.idServer, userData['id_server']?.toString() ?? '');
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
    SpUtil.putString(StorageKeys.url, AppConstants.localApiBaseUrl);
  }

  /// Navigates to the correct home screen based on user group.
  void _navigateToHome() {
    if (!mounted) return;

    String? idGroups = SpUtil.getString(StorageKeys.idGroups);
    
    if (idGroups == "3" || idGroups == "5") {
      SpUtil.putBool(StorageKeys.isLogin, true);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (idGroups == "2") {
      SpUtil.putBool(StorageKeys.isLogin, true); // Assuming admin should also be marked as logged in
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      SpUtil.clear(); // Clear storage if group is unknown
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double referenceWidth = 381.0;
    final double scaleFactor = screenWidth / referenceWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/new/login.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            width: screenWidth,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24 * scaleFactor, 40 * scaleFactor, 24 * scaleFactor, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50 * scaleFactor),
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 230 * scaleFactor,
                      height: 40 * scaleFactor,
                      child: Image.asset(
                        "assets/new/login-header.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 80 * scaleFactor),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, Selamat Datang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isDeviceInfoReady)
                        Padding(
                          padding: EdgeInsets.only(top: 8 * scaleFactor),
                          child: Row(
                            children: [
                              if (_deviceInfoError)
                                Icon(Icons.error_outline, color: Colors.orange, size: 16 * scaleFactor)
                              else
                                SizedBox(
                                  width: 16 * scaleFactor,
                                  height: 16 * scaleFactor,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                _deviceInfoError
                                    ? 'Error mendapatkan info perangkat'
                                    : 'Memuat informasi perangkat...',
                                style: TextStyle(
                                  color: _deviceInfoError ? Colors.orange : Colors.white70,
                                  fontSize: 12 * scaleFactor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 25 * scaleFactor),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_usernameController, ' Username', false),
                        SizedBox(height: 25 * scaleFactor),
                        _buildTextField(_passwordController, ' Password', true),
                      ],
                    ),
                  ),
                  SizedBox(height: 25 * scaleFactor),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isDeviceInfoReady) ? null : _startLoading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(246, 54, 51, 100),
                        padding: EdgeInsets.symmetric(horizontal: 50 * scaleFactor, vertical: 20 * scaleFactor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * scaleFactor),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Processing..' : !_isDeviceInfoReady ? 'Memuat...' : 'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0 * scaleFactor,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Center(
                      child: Text(
                        'App version 1.0.10',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100, fontSize: 11),
                      ),
                    ),
                    subtitle: const Text(''), // Subtitle kept as empty string as in original
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: textWhiteGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_passwordVisible,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: heading6.copyWith(color: textGrey),
          suffixIcon: isPassword
              ? IconButton(
                  color: textGrey,
                  splashRadius: 1,
                  icon: Icon(_passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: _togglePasswordVisibility,
                )
              : null,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Mohon masukkan $hintText'.trim();
          }
          return null;
        },
      ),
    );
  }
}