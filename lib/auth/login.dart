import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mobileabsensi/core.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';
import 'package:mobileabsensi/services/alert.dart';
import 'package:sp_util/sp_util.dart';

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

  // void _showMsg(String msg) {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  // }

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
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 5));

      final simpel = json.decode(response.body);
      // print(simpel);
      if (response.statusCode == 200) {
        if(simpel["success"] == 1){
          if(simpel["id_groups"] == 2){
            await _syncUserData(simpel);
          }else{
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
          Alert.alerterror(context, 'Pastikan perangkat terhubung ke Internet');
        });
      }
      if (kDebugMode) {
        print(Exception(e));
      }
    }
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> simpel) async {

    final getDeviceResponse = await post(
      Uri.parse('http://mobileabsensi1.pasamanbaratkab.go.id/api_android_v2/api/getDevice'),
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
  }

  Future<void> _syncUserData(Map<String, dynamic> body) async {

    final dataWifiResponse = await get(
      Uri.parse('http://mobileabsensi1.pasamanbaratkab.go.id/api_android_v2/api/wifi/${body['username_admin']}'),
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
    SpUtil.putString('url', 'http://mobileabsensi1.pasamanbaratkab.go.id/api_android_v2');
  }

  void _navigateToHome() {
      if (SpUtil.getString('id_groups') == "2") {
        SpUtil.putBool('isLogin', true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Admin()),
        );

      } else if (SpUtil.getString('id_groups') == "5" || SpUtil.getString('id_groups') == "3") {
        SpUtil.putBool('isLogin', true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home(title: 'Dashboard')),
        );

      } else {
        SpUtil.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/ui/bg-white.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 240),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Absensi\nLogin',
                      style: heading2.copyWith(color: textBlack),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/images/accent.png',
                      width: 99,
                      height: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(username, 'Username', false),
                      const SizedBox(height: 25),
                      _buildTextField(password, 'Password', true),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startLoading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 50, 106),
                      padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      _isLoading ? 'Processing..' : 'Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
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
        borderRadius: BorderRadius.circular(14),
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
