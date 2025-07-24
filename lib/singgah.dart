import 'package:flutter/material.dart';
import 'package:mobileabsensi/auth/login.dart';
import 'package:mobileabsensi/frontend/admin/home.dart';
import 'package:mobileabsensi/frontend/dashboard.dart';
import 'package:sp_util/sp_util.dart';

class Singgah extends StatelessWidget {
  const Singgah({super.key});

  @override
  Widget build(BuildContext context) {
    String? idGroups = SpUtil.getString('id_groups');
    if (idGroups == "3" || idGroups == "5") {
      return const Dashboard(initialIndex: 0,);
    } else if (idGroups == "2") {
      return const Admin();
    } else {
      SpUtil.clear();
      return const Login();
    }
  }
}