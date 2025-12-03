import 'package:flutter/material.dart';
import 'package:mobileabsensi/frontend/navigasi.dart';
import 'package:sp_util/sp_util.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  
  @override
  
State<Header> createState() => _HeaderState();
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
      height: size.height * 0.20 ,
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
              // child: CircleAvatar(
              //   radius: deviceWidth * 0.08,
              //   backgroundImage:
              //       const AssetImage('assets/images/logo.png'),
              // ),
              child: Container(
                width: deviceWidth * 0.15,
                height: deviceWidth * 0.15,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
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
            
          ],
        ),
      ),
    );
  }
}
