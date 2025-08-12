import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:sp_util/sp_util.dart';

// Import your main application widget, assuming it's named MobileAbsensiApp
// import 'package:mobileabsensi/main_app.dart'; // Example: Adjust this import based on your actual file structure

// Define your colors and text styles if they are not in core.dart or a global file
const Color textWhiteGrey = Color(0xFFF1F1F1);
const Color textGrey = Color(0xFFAAAAAA);
const TextStyle heading6 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

// Dummy root widget for demonstration. Replace with your actual root widget.
class MobileAbsensiApp extends StatelessWidget {
  const MobileAbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Absensi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Login(), // Your Login screen as the initial route
      routes: {
        '/login': (context) => const Login(),
        '/dashboard': (context) => const DashboardScreen(), // Assuming you have a DashboardScreen
        '/admin': (context) => const AdminScreen(), // Assuming you have an AdminScreen
      },
    );
  }
}

// Dummy DashboardScreen and AdminScreen for compilation
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Welcome to Dashboard!')),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: const Center(child: Text('Welcome to Admin Panel!')),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  bool passwordVisible = false;
  bool _isLoading = false;
  bool _isDeviceInfoReady = false; // Track if device info is ready
  final _formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  Timer? _timer;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
  }

  // Initialize device info and wait for completion
  Future<void> _initializeDeviceInfo() async {
    try {
      await initPlatformState();
      if (mounted) {
        setState(() {
          _isDeviceInfoReady = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize device info: $e");
      }
      // Retry after 2 seconds if failed
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _initializeDeviceInfo();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      // Get Android device info
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceData = _readAndroidBuildData(androidInfo);

      // Store device info with validation
      if (deviceData['id'] != null && deviceData['id'].toString().isNotEmpty) {
        await SpUtil.putString('device_id', deviceData['id'].toString());
        if (kDebugMode) {
          print("Device ID stored: ${deviceData['id']}");
        }
      } else {
        // Fallback to androidId if id is null
        final fallbackId = androidInfo.id;
        await SpUtil.putString('device_id', fallbackId);
        if (kDebugMode) {
          print("Using fallback device ID: $fallbackId");
        }
      }

      if (deviceData['version.release'] != null && deviceData['version.release'].toString().isNotEmpty) {
        await SpUtil.putString('system_version', deviceData['version.release'].toString());
        if (kDebugMode) {
          print("System version stored: ${deviceData['version.release']}");
        }
      } else {
        // Fallback system version
        await SpUtil.putString('system_version', 'Unknown');
        if (kDebugMode) {
          print("Using fallback system version: Unknown");
        }
      }

      // Update internal device data
      setState(() {
        _deviceData = deviceData;
      });

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Platform exception: $e");
      }
      // Set fallback values on error
      await SpUtil.putString('device_id', 'fallback_device_${DateTime.now().millisecondsSinceEpoch}');
      await SpUtil.putString('system_version', 'Unknown');
      
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version: ${e.message}'
      };
    } catch (e) {
      if (kDebugMode) {
        print("General exception in initPlatformState: $e");
      }
      // Set fallback values on any error
      await SpUtil.putString('device_id', 'fallback_device_${DateTime.now().millisecondsSinceEpoch}');
      await SpUtil.putString('system_version', 'Unknown');
      
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get device information: $e'
      };
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

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void _startLoading() async {
    // Check if device info is ready before proceeding
    if (!_isDeviceInfoReady) {
      if (mounted) {
        Alert.alertwarning(context, 'Sedang memuat informasi perangkat, mohon tunggu...');
      }
      return;
    }

    // Validate device info before login
    final deviceId = SpUtil.getString('device_id');
    final systemVersion = SpUtil.getString('system_version');
    
    if (deviceId == null || deviceId.isEmpty || systemVersion == null || systemVersion.isEmpty) {
      if (mounted) {
        Alert.alerterror(context, 'Gagal mendapatkan informasi perangkat. Mohon restart aplikasi.');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        await _login(username.text, password.text);
      } catch (error) {
        if (kDebugMode) {
          print("Error: $error");
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login(String username, String password) async {
    // Validate device info again before making API calls
    final deviceId = SpUtil.getString('device_id');
    final systemVersion = SpUtil.getString('system_version');
    
    if (kDebugMode) {
      print("Device ID: $deviceId");
      print("System Version: $systemVersion");
    }

    if (deviceId == null || deviceId.isEmpty) {
      if (mounted) {
        Alert.alerterror(context, 'Device ID tidak ditemukan. Mohon restart aplikasi.');
      }
      return;
    }

    if (systemVersion == null || systemVersion.isEmpty) {
      if (mounted) {
        Alert.alerterror(context, 'System version tidak ditemukan. Mohon restart aplikasi.');
      }
      return;
    }
 
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await post(
        Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/api/model_login2.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'User-Agent': 'Dart/Flutter (mobile app)'
        },
        body: {
          'username': username,
          'password': password,
          'device_id': SpUtil.getString('device_id'),
          'system_version': SpUtil.getString('system_version'),
        },
      ).timeout(const Duration(seconds: 10));

      final simpel = json.decode(response.body);
      if (response.statusCode == 200) {
        if (simpel["success"] == 1) {
          SpUtil.putString('id_server', simpel['id_server'].toString());
          if (simpel["id_groups"] == 2) {
            await _syncUserData(simpel);
          } else {
            await _handleSuccessfulLogin(simpel);
          }
        } else {
          if (mounted) {
            Alert.alertwarning(context, simpel["message"]);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          Alert.alerterror(context, 'Tidak dapat terhubung ke server, silahkan coba lagi nanti!');
        });
      }
      if (kDebugMode) {
        print(Exception(e));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    } 
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> simpel) async {
    try {
      final deviceId = SpUtil.getString('device_id');
      final systemVersion = SpUtil.getString('system_version');
      
      final getDeviceResponse = await post(
        Uri.parse('http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/api/getDevice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_user': simpel['id_user'].toString(),
          'device_id': deviceId,
          'username': simpel['username'],
          'versiApp': systemVersion,
        }),
      ).timeout(const Duration(seconds: 15));
      
      final deviceData = json.decode(getDeviceResponse.body);
      if (deviceData['status'] == true) {
        await _syncUserData(simpel);
      } else {
        if (mounted) {
          Alert.alertwarning(context, deviceData["message"]);
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, 'Gagal mendapatkan data perangkat');
      }
      if (kDebugMode) {
        print(Exception(e));
      }
    }
  }

  Future<void> _syncUserData(Map<String, dynamic> body) async {
    try {
      final dataWifiResponse = await get(
        Uri.parse('http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/api/wifi/${body['username_admin']}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final dataPegawaiResponse = await get(
        Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/getByIdUser.php?id_user=${body['id_user']}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final responseData = json.decode(dataPegawaiResponse.body);
      final user = responseData['data'];

      for (var userData in user) {
        _storeUserData(userData);
      }

      if (dataWifiResponse.statusCode == 200) {
        final wifiData = json.decode(dataWifiResponse.body)['data'];
        SpUtil.putString('wifi_data', json.encode(wifiData));
        _navigateToHome();
      } else {
        if (mounted) {
          Alert.alerterror(context, 'Gagal menyingkronkan wifi, silahkan login ulang');
        }
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, 'Gagal menyingkronkan data pengguna');
      }
      if (kDebugMode) {
        print(Exception(e));
      }
    }
  }

  void _storeUserData(Map<String, dynamic> userData) {
    SpUtil.putString('id_server', userData['id_server'].toString());
    SpUtil.putString('id_user', userData['id_user'].toString());
    SpUtil.putString('id_instansi', userData['id_instansi'].toString());
    SpUtil.putString('id_groups', userData['id_groups']?.toString() ?? '');
    SpUtil.putString('id_user_pimpinan', userData['id_user_parent']?.toString() ?? '');
    SpUtil.putString('id_admin_instansi', userData['id_admin_instansi']?.toString() ?? '');
    SpUtil.putString('id_pimpinan', userData['id_pimpinan']?.toString() ?? '');
    SpUtil.putString('username', userData['username'].replaceAll('"', ''));
    SpUtil.putString('username_admin', userData['username_admin'].replaceAll('"', ''));
    SpUtil.putString('nama_lengkap', userData['nama_lengkap'].replaceAll('"', ''));
    SpUtil.putString('nama_instansi', userData['nama_instansi']?.toString() ?? '');
    SpUtil.putString('nama_atasan', userData['nama_atasan']?.toString() ?? '');
    SpUtil.putString('nip_atasan', userData['nip_atasan']?.toString() ?? '');
    SpUtil.putString('jabatan_atasan', userData['jabatan_atasan']?.toString() ?? '');
    SpUtil.putString('url', 'http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2');
  }

  void _navigateToHome() {
    String? idGroups = SpUtil.getString('id_groups');
    String? idInstansi = SpUtil.getString('id_admin_instansi');
    
    if (idGroups == "3" || idGroups == "5") {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (idGroups == "2") {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      SpUtil.clear();
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
                      if (!_isDeviceInfoReady) // Show loading indicator
                        Padding(
                          padding: EdgeInsets.only(top: 8 * scaleFactor),
                          child: Row(
                            children: [
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
                                'Memuat informasi perangkat...',
                                style: TextStyle(
                                  color: Colors.white70,
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
                        _buildTextField(username, ' Username', false),
                        SizedBox(height: 25 * scaleFactor),
                        _buildTextField(password, ' Password', true),
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
                  SizedBox(height: 25 * scaleFactor),
                  // Debug info (remove in production)
                  // if (kDebugMode && _isDeviceInfoReady)
                    // Container(
                    //   padding: EdgeInsets.all(8 * scaleFactor),
                    //   decoration: BoxDecoration(
                    //     color: Colors.black54,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         'Debug Info:',
                    //         style: TextStyle(color: Colors.white, fontSize: 12 * scaleFactor, fontWeight: FontWeight.bold),
                    //       ),
                    //       Text(
                    //         'Device ID: ${SpUtil.getString('device_id') ?? 'null'}',
                    //         style: TextStyle(color: Colors.white, fontSize: 10 * scaleFactor),
                    //       ),
                    //       Text(
                    //         'System Version: ${SpUtil.getString('system_version') ?? 'null'}',
                    //         style: TextStyle(color: Colors.white, fontSize: 10 * scaleFactor),
                    //       ),
                    //     ],
                    //   ),
                    // ),
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
        obscureText: isPassword && !passwordVisible,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: heading6.copyWith(color: textGrey),
          suffixIcon: isPassword
              ? IconButton(
                  color: textGrey,
                  splashRadius: 1,
                  icon: Icon(passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: togglePassword,
                )
              : null,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }
}