import 'dart:async';
import 'package:flutter/material.dart';

import 'auth/login.dart';

void openSplashScreen(BuildContext context) {
  var durasiSplash = const Duration(seconds: 2);
  Timer(durasiSplash, () {
    // Pindah ke halaman login
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) {
      // Return HomePage();
      return const Login();
    }));
  });
}
