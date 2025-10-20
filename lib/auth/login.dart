import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:sp_util/sp_util.dart';

// Define your colors and text styles
const Color textWhiteGrey = Color(0xFFF1F1F1);
const Color textGrey = Color(0xFFAAAAAA);
const TextStyle heading6 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  bool passwordVisible = false;
  bool _isLoading = false;
  bool _isDeviceInfoReady = false;
  bool _deviceInfoError = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  Timer? _timer;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> deviceData = <String, dynamic>{};
  
  @override
  void initState() {
    super.initState();
    final deviceId = SpUtil.getString('device_id');
    if(SpUtil.getBool('is_login') == true){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }else{
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeApp();
      });
    }
    if (deviceId == null || deviceId.isEmpty) {
        _initializeApp();
    } 
  }
 

  Widget _infoTile(String title, String subtitle) {
    return ListTile(
      title: Center(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w100, fontSize: 11),)),
      subtitle: Text(subtitle.isEmpty ? '' : subtitle),
    );
  }
  // Initialize app with device info
  Future<void> _initializeApp() async {
    // Initialize shared preferences first
    await SpUtil.getInstance();
    
    // Then get device info
    await _initializeDeviceInfo();
  }

  // Initialize device info with retry mechanism
  Future<void> _initializeDeviceInfo() async {
    try {
      await initPlatformState();
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
      Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDeviceInfoReady) {
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
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Get Android device info
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = _readAndroidBuildData(androidInfo);

        // Store device info with proper validation
        String deviceId = deviceData['id']?.toString() ?? '';
        if (deviceId.isEmpty) {
          deviceId = androidInfo.id; // Use androidId as fallback
        }
        
        String systemVersion = deviceData['version.release']?.toString() ?? '';
        if (systemVersion.isEmpty) {
          systemVersion = androidInfo.version.release;
        }

        await SpUtil.putString('device_id', deviceId);
        await SpUtil.putString('system_version', systemVersion);

        if (kDebugMode) {
          // print("Device ID stored: $deviceId");
          // print("System version stored: $systemVersion");
        }

        // Update internal device data
        setState(() {
          deviceData = deviceData;
        });
      } else {
        // For non-Android platforms, use fallback values
        await _setFallbackDeviceInfo();
      }

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Platform exception: $e");
      }
      await _setFallbackDeviceInfo();
    } catch (e) {
      if (kDebugMode) {
        print("General exception in initPlatformState: $e");
      }
      await _setFallbackDeviceInfo();
    }
  }

  // Set fallback device information
  Future<void> _setFallbackDeviceInfo() async {
    final fallbackId = 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    await SpUtil.putString('device_id', fallbackId);
    await SpUtil.putString('system_version', 'Unknown');
    
    setState(() {
      deviceData = {
        'Error': 'Using fallback device info',
        'id': fallbackId,
        'version.release': 'Unknown'
      };
    });
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
      if (_deviceInfoError) {
        Alert.alerterror(context, 'Gagal mendapatkan informasi perangkat. Mohon restart aplikasi.');
      } else {
        Alert.alertwarning(context, 'Sedang memuat informasi perangkat, mohon tunggu...');
      }
      return;
    }

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _login(username.text, password.text);
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
      if (mounted) {
        Alert.alerterror(context, 'Terjadi kesalahan saat login');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login(String username, String password) async {
    // await _initializeApp();
    // Validate device info 
    // print(SpUtil.getString('device_id'));
    // if (kDebugMode) {
    //   print("Login attempt with:");
    //   print("Device ID: $deviceId");
    //   print("System Version: $systemVersion");
    // }

    if (SpUtil.getString('device_id') == null || SpUtil.getString('system_version') == null) {
      if (mounted) {
        Alert.alerterror(context, 'Informasi perangkat tidak valid. Mohon restart aplikasi.');
      }
      return;
    }

    try {
      final response = await post(
        Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/api/model_login2.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'username': username,
          'password': password,
          'device_id': SpUtil.getString('device_id'),
          'system_version': SpUtil.getString('system_version'),
        },
      ).timeout(const Duration(seconds: 15));

      final simpel = json.decode(response.body);
      if (response.statusCode == 200) {
        if (simpel["success"] == 1) {
          SpUtil.putString('id_server', simpel['id_server'].toString());
          if (simpel["id_groups"] == 2) {
            await _syncUserData(simpel);
          } else {
            if(simpel["id_user"] != SpUtil.getString('id_user')){
              SpUtil.clear();
              await _handleSuccessfulLogin(simpel);
            }else{
              await _handleSuccessfulLogin(simpel);
            }
          }
        } else {
          if (mounted) {
            Alert.alertwarning(context, simpel["message"]);
          }
        }
      } else {
        if (mounted) {
          Alert.alerterror(context, 'Server error: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      if (mounted) {
        Alert.alerterror(context, 'Timeout terhubung ke server');
      }
    } catch (e) {
      if (mounted) {
        Alert.alerterror(context, 'Tidak dapat terhubung ke server, silahkan coba lagi nanti!');
      }
      if (kDebugMode) {
        print(Exception(e));
      }
    }
  }
 

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> simpel) async {
    try {
      if(simpel['id_groups'] == "2"){
        await _syncUserData(simpel);
      }else{
        final getDeviceResponse = await post(
        Uri.parse('http://192.168.10.46:8000/api/getDevice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_user': simpel['id_user'].toString(),
          'device_id': SpUtil.getString('device_id'),
          'username': simpel['username'],
          'versiApp': SpUtil.getString('system_version'),
        }),
      ).timeout(const Duration(seconds: 15));
      
      final deviceData = json.decode(getDeviceResponse.body);
        if (deviceData['status'] == true) {
          if(simpel['id_user'].toString() == SpUtil.getString('id_user')){
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            } 
          }else{
            await _syncUserData(simpel);
          }
        } else {
          if (mounted) {
            Alert.alertwarning(context, deviceData["message"]);
          }
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
        // Uri.parse('http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/api/wifi/${body['username_admin']}'),
        Uri.parse('http://192.168.10.46:8000/api/wifi/${body['username_admin']}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final dataShift = await get(
        // Uri.parse('http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/api/jam-kerja/${body['id_user']}'),
        Uri.parse('http://192.168.10.46:8000/api/jam-kerja/${body['id_user']}'),
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
      if (dataShift.statusCode == 200) {
        final shiftData = json.decode(dataShift.body)['data'];
        SpUtil.putString('shift_data', json.encode(shiftData));
        _navigateToHome();
      } else {
        // if (mounted) {
        //   Alert.alerterror(context, 'Gagal mendapatkan jam kerja, silahkan login ulang');
        // }
        return;
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
    SpUtil.putString('id_type', userData['id_type'].toString());
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
    // SpUtil.putString('url', 'http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2');
    SpUtil.putString('url', 'http://192.168.10.46:8000');
  }

  void _navigateToHome() {
    String? idGroups = SpUtil.getString('id_groups');
    if (idGroups == "3" || idGroups == "5") {
      // if(SpUtil.getString('id_user') == '9024'){
        SpUtil.putBool('is_login', true);
        Navigator.pushReplacementNamed(context, '/dashboard');
      // }else{
      //   SpUtil.clear();
      //   Navigator.pushReplacementNamed(context, '/login');
      //   return;
      // }
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
                      // if (!_isDeviceInfoReady)
                      //   Padding(
                      //     padding: EdgeInsets.only(top: 8 * scaleFactor),
                      //     child: Row(
                      //       children: [
                      //         if (_deviceInfoError)
                      //           Icon(Icons.error_outline, color: Colors.orange, size: 16 * scaleFactor)
                      //         else
                      //           SizedBox(
                      //             width: 16 * scaleFactor,
                      //             height: 16 * scaleFactor,
                      //             child: const CircularProgressIndicator(
                      //               strokeWidth: 2,
                      //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //             ),
                      //           ),
                      //         SizedBox(width: 8 * scaleFactor),
                      //         Text(
                      //           _deviceInfoError 
                      //             ? 'Error mendapatkan info perangkat'
                      //             : 'Memuat informasi perangkat...',
                      //           style: TextStyle(
                      //             color: _deviceInfoError ? Colors.orange : Colors.white70,
                      //             fontSize: 12 * scaleFactor,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
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
                   _infoTile('App version 1.0.10', ''),
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