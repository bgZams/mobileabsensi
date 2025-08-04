import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mobileabsensi/core.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  String? deviceId;
  String? systemVersion;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void _startLoading() async {
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

  Future<void> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      setState(() {
        deviceId = androidInfo.id;
        systemVersion = androidInfo.version.release;
      });
    } catch (e) {
      setState(() {
        deviceId = 'Failed to get device ID';
        systemVersion = 'Failed to get system version';
      });
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> _login(String username, String password) async {
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
        },
      ).timeout(const Duration(seconds: 10));

      final simpel = json.decode(response.body);
      if (response.statusCode == 200) {
        if (simpel["success"] == 1) {
        if (simpel["vesi_app"] == "1.5") {
          if (mounted) {
            Alert.alertwarning(context, simpel["message"]);
          }
        }
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
          Alert.alerterror(context, 'Pastikan perangkat terhubung ke Internet {$e}');
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
        SpUtil.putString('deviceId', deviceId!);
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
        Alert.alerterror(context, 'Gagal menyingkronkan data pengguna: {$e}');
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
    // if (idInstansi == '4393') {
      if (idGroups == "3" || idGroups == "5") {
        Navigator.pushReplacementNamed(context, '/dashboard');
        // print('1');

      } else if (idGroups == "2") {
        Navigator.pushReplacementNamed(context, '/admin');
        // print('2');

      } else {
        SpUtil.clear();
        Navigator.pushReplacementNamed(context, '/login');
        // print('2');

      }
    // } else {
    //   SpUtil.clear();
    //   Alert.alerterror(context, 'Tahap uji coba silahkan gunakan aplikasi yang lama');
    //   Navigator.pushReplacementNamed(context, '/login');
    // }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Anda bisa menentukan faktor skala berdasarkan lebar/tinggi layar
    // Misalnya, anggap desain Anda optimal di lebar 381px.
    const double referenceWidth = 381.0;
    final double scaleFactor = screenWidth / referenceWidth; // Skala berdasarkan lebar

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/new/login.png"),
            fit: BoxFit.cover, // Tetap BoxFit.cover untuk background
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight, // Pastikan SingleChildScrollView mengisi tinggi layar
            width: screenWidth, // Pastikan SingleChildScrollView mengisi lebar layar
            child: Padding(
              // Skala padding
              padding: EdgeInsets.fromLTRB(24 * scaleFactor, 40 * scaleFactor, 24 * scaleFactor, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50 * scaleFactor), // Skala tinggi SizedBox
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 230 * scaleFactor, // Skala lebar gambar
                      height: 40 * scaleFactor, // Skala tinggi gambar
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
                          fontSize: 30 * scaleFactor, // Skala ukuran font
                          fontWeight: FontWeight.bold,
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
                    width: double.infinity, // Ambil lebar penuh yang tersedia
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startLoading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(246, 54, 51, 100),
                        padding: EdgeInsets.symmetric(horizontal: 50 * scaleFactor, vertical: 20 * scaleFactor), // Skala padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * scaleFactor), // Skala border radius
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Processing..' : 'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0 * scaleFactor, // Skala ukuran font
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25 * scaleFactor),
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