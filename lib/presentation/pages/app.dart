// lib/presentation/pages/app.dart

import 'package:flutter/material.dart';
import 'package:mobileabsensi/core/constants/app_constants.dart';
import 'package:mobileabsensi/core/constants/routes.dart';
import 'package:mobileabsensi/core/services/overlay_service.dart';
import 'package:sp_util/sp_util.dart';
import 'package:mobileabsensi/singgah.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey screenshotKey = GlobalKey();
  bool _isButtonShown = false;

  @override
  Widget build(BuildContext context) {
    final idGroups = SpUtil.getString('id_groups');
    Widget homeWidget;
    if (idGroups == "3" || idGroups == "5") {
      homeWidget = const Singgah();
    } else if (idGroups == "2") {
      homeWidget = const Admin();
    } else {
      homeWidget = const Login();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Absensi',
      navigatorKey: navigatorKey,
      
      home: Builder(
        builder: (context) {
          // Gunakan addPostFrameCallback untuk menunda eksekusi
          if (!_isButtonShown) {
            _isButtonShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Kode di dalam sini akan dijalankan setelah frame selesai dibangun
              OverlayService.showScreenshotButton(
                context: context,
                screenshotKey: screenshotKey,
                onScreenshotTaken: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Screenshot berhasil diambil!')),
                  );
                },
                onScreenshotSaved: (String? path) {
                  if (path != null) {
                  }
                },
              );
            });
          }
          
          return RepaintBoundary(
            key: screenshotKey,
            child: homeWidget,
          );
        },
      ),
      
      routes: appRoutes,
      onGenerateRoute: onGenerateRoute,
    );
  }
}