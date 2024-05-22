import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mobileabsensi/core.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sp_util/sp_util.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool passwordVisible = false;
  final bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController versi = TextEditingController();

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _secureText = true;

  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  _showMsg(msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _login(String username, password) async {
    try {
      Response response = await post(
          Uri.parse(
              'https://simpel.pasamanbaratkab.go.id/api_android/simaya/api/model_login2.php'),
          body: {'username': username, 'password': password});
      var body = json.decode(response.body);

      if (response.statusCode == 200) {
        if (body["success"] == 1) {
          Response dataWifi = await get(
            Uri.parse(
                '${body['domain']}/api_mobile/data_wifi/validasi_absen/${body['username_admin']}'),
            headers: {
              'Content-type': 'application/json',
              'Accept': 'application/json'
            },
          );

          Response datapegawai = await get(
            Uri.parse(
                'https://simpel.pasamanbaratkab.go.id/api_android/simaya/getByIdUser.php?id_user=${body['id_user']}'),
            headers: {
              'Content-type': 'application/json',
              'Accept': 'application/json'
            },
          );
          var responseData = json.decode(datapegawai.body);
          var user = responseData['data'];
          for (var userData in user) {
            SpUtil.putString('id_server', userData['id_server']);
            SpUtil.putString('id_user', userData['id_user']);
            SpUtil.putString('id_instansi', userData['id_instansi']);
            SpUtil.putString('id_groups', userData['id_groups'] ?? '');
            SpUtil.putString(
                'id_user_pimpinan', userData['id_user_parent'] ?? '');
            SpUtil.putString(
                'id_admin_instansi', userData['id_admin_instansi'] ?? '');
            SpUtil.putString('id_pimpinan', userData['id_pimpinan'] ?? '');
            String usernameString = userData['username'];
            SpUtil.putString('username', usernameString.replaceAll('"', ''));
            String userAdminString = userData['username_admin'];
            SpUtil.putString(
                'username_admin', userAdminString.replaceAll('"', ''));
            String namaLengkap = userData['nama_lengkap'];
            SpUtil.putString('nama_lengkap', namaLengkap.replaceAll('"', ''));
            SpUtil.putString('nama_instansi', userData['nama_instansi'] ?? '');
            SpUtil.putString('nama_atasan', userData['nama_atasan'] ?? '');
            SpUtil.putString('nip_atasan', userData['nip_atasan'] ?? '');
            SpUtil.putString(
                'jabatan_atasan', userData['jabatan_atasan'] ?? '');
            // SpUtil.putString('url', userData['url'] ?? '');
            SpUtil.putString('url', 'http://192.168.223.46');
          }

          SpUtil.putBool('isLogin', true);

          if (dataWifi.statusCode == 200) {
            List<dynamic> wifiData = json.decode(dataWifi.body);
            SpUtil.putString('wifi_data',
                json.encode(wifiData)); // Simpan semua data sebagai JSON
          } else {
            // Handle error jika diperlukan
          }
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const Home(
                      title: 'Dashboard',
                    )),
          );
        } else {
          // ignore: use_build_context_synchronously
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text: body["message"],
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(Exception(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Absensi\nLogin',
                      style: heading2.copyWith(color: textBlack),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Image.asset(
                      'assets/images/accent.png',
                      width: 99,
                      height: 4,
                    )
                  ],
                ),
                const SizedBox(
                  height: 100,
                ),
                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: textWhiteGrey,
                              borderRadius: BorderRadius.circular(14)),
                          child: TextFormField(
                            controller: username,
                            decoration: InputDecoration(
                                hintText: 'Usename',
                                hintStyle: heading6.copyWith(color: textGrey),
                                border: const OutlineInputBorder(
                                    borderSide: BorderSide.none)),
                            validator: (usernameValue) {
                              if (usernameValue!.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: textWhiteGrey,
                              borderRadius: BorderRadius.circular(14)),
                          child: TextFormField(
                              controller: password,
                              obscureText: !passwordVisible,
                              decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: heading6.copyWith(color: textGrey),
                                  suffixIcon: IconButton(
                                    color: textGrey,
                                    splashRadius: 1,
                                    icon: Icon(passwordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: togglePassword,
                                  ),
                                  border: const OutlineInputBorder(
                                      borderSide: BorderSide.none)),
                              validator: (passwordValue) {
                                if (passwordValue!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              }),
                        )
                      ],
                    )),
                const SizedBox(
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const CustomCheckbox(),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'Remember me',
                      style: regular16pt,
                    )
                  ],
                ),
                const SizedBox(
                  height: 32,
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _login(username.text.toString(),
                                password.text.toString());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold)),
                  child: Text(
                    _isLoading ? 'Processing..' : 'Login',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16.0,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       'Belum punya akun? ',
                //       style: regular16pt.copyWith(color: textGrey),
                //     ),
                //     GestureDetector(
                //       onTap: () {
                //         Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //                 builder: (context) => const Register()));
                //       },
                //       child: Text(
                //         'Register',
                //         style: regular16pt.copyWith(color: primaryBlue),
                //       ),
                //     )
                //   ],
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
