import 'package:flutter/material.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';

class Panduan extends StatefulWidget {
  const Panduan({super.key});

  @override
  State<Panduan> createState() => _PanduanState();
}

class _PanduanState extends State<Panduan> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
        WidgetNavbar(title: 'Panduan',),
          Column(
            children: [
              SizedBox(height: size.height * 0.15),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                    children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panduan Penggunaan Aplikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                        SizedBox(height: 16,),
                        Text('1. Pastikan Anda sudah melakukan registrasi dan login ke dalam aplikasi.', style: TextStyle(fontSize: 16),),
                        SizedBox(height: 8,),
                        Text('2. Pilih menu yang ingin Anda gunakan.', style: TextStyle(fontSize: 16),),
                        SizedBox(height: 8,),
                        Text('3. Ikuti instruksi yang diberikan pada setiap menu.', style: TextStyle(fontSize: 16),),
                        SizedBox(height: 8,),
                        Text('4. Jika ada masalah, silakan hubungi admin.', style: TextStyle(fontSize: 16),),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            SizedBox(height: size.height * 0.02),
            ],
          ),
        ],  
      ),
    );
  }
}