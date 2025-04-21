import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobileabsensi/frontend/absen/laporan_harian.dart';
import 'package:mobileabsensi/frontend/navigasi.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sp_util/sp_util.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  String? nama;
  String? instansi;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          nama = SpUtil.getString("nama_lengkap");
          instansi = SpUtil.getString("nama_instansi");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceWidth = size.width;

    return Container(
      height: size.height * 0.20,
      width: deviceWidth,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/new/home-header-bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(deviceWidth * 0.04),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Navigasi()),
                );
              },
              child: CircleAvatar(
                radius: deviceWidth * 0.08,
                backgroundImage:
                    const AssetImage('assets/images/profile.png'),
              ),
            ),
            SizedBox(width: deviceWidth * 0.02),
            SizedBox(
              width: deviceWidth * 0.50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama ?? '',
                    style: TextStyle(
                      fontSize: deviceWidth * 0.03,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    instansi ?? '',
                    style: TextStyle(
                      fontSize: deviceWidth * 0.03,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LaporanHarian()),
              );
              },
              child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LaporanHarian()),
                );
                },
                child: SizedBox(
                width: deviceWidth * 0.15,
                height: deviceWidth * 0.08,
                child: const Icon(Icons.note_alt,
                  color: Color(0xFFC983DE), size: 40),
                ),
              ),
              ),
              ),
            SizedBox(width: deviceWidth * 0.02),
          ],
        ),
      ),
    );
  }
}
