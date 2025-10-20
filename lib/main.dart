import 'package:flutter/material.dart';
import 'package:mobileabsensi/core/services/initialization_service.dart';
import 'package:mobileabsensi/presentation/pages/app.dart';

void main() async {
  await initializeApp();
  runApp(const MyApp());
}