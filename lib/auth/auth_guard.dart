import 'package:flutter/material.dart';
import 'package:sp_util/sp_util.dart';
import 'package:mobileabsensi/auth/login.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  
  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cek status login
    final isLoggedIn = SpUtil.getBool(StorageKeys.isLogin) ?? false;
    
    if (!isLoggedIn) {
      // Jika belum login, redirect ke login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return child;
  }
}