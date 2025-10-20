// lib/presentation/widgets/screen_wrapper.dart

import 'package:flutter/material.dart';

/// ScreenWrapper yang TIDAK menampilkan screenshot button
/// karena sudah ditangani secara global di MyApp
class ScreenWrapper extends StatelessWidget {
  final Widget child;
  
  const ScreenWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Langsung return child tanpa GlobalScreenshot
    // karena overlay sudah dihandle di level app
    return child;
  }
}