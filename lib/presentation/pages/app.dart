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
      
      home: _ScreenshotWrapper(
        screenshotKey: screenshotKey,
        child: homeWidget,
      ),
      
      routes: appRoutes,
      onGenerateRoute: onGenerateRoute,
    );
  }
}

// Widget wrapper yang menangani screenshot overlay HANYA SEKALI
class _ScreenshotWrapper extends StatefulWidget {
  final GlobalKey screenshotKey;
  final Widget child;

  const _ScreenshotWrapper({
    required this.screenshotKey,
    required this.child,
  });

  @override
  State<_ScreenshotWrapper> createState() => _ScreenshotWrapperState();
}

class _ScreenshotWrapperState extends State<_ScreenshotWrapper> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Tampilkan overlay setelah widget pertama kali di-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan hanya dipanggil sekali menggunakan flag lokal
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        OverlayService.showScreenshotButton(
          context: context,
          screenshotKey: widget.screenshotKey,
          onScreenshotTaken: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screenshot berhasil diambil!')),
              );
            }
          },
          onScreenshotSaved: (String? path) {
            // Handle jika perlu
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.screenshotKey,
      child: widget.child,
    );
  }
}