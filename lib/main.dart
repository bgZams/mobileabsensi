import 'package:flutter/material.dart';
import 'package:mobileabsensi/core/services/initialization_service.dart';
import 'package:mobileabsensi/presentation/pages/app.dart';

import 'core/services/overlay_service.dart';

void main() async {
  await initializeApp();
  OverlayService.reset();
  runApp(const MyApp());
}