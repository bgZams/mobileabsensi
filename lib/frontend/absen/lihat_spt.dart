import 'package:flutter/material.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';

class LihatSpt extends StatelessWidget {
  final String imageUrl;
  final String keterangan;

  const LihatSpt({required this.imageUrl, required this.keterangan, super.key});

  @override
  Widget build(BuildContext context) {
    String decodedUrl = Uri.decodeComponent(imageUrl);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
     
       
      body: Stack(
        children: [
          WidgetNavbar(title: 'Detail Foto'),
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
                  child:   Column(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: size.width * 0.9,
                            height: size.height * 0.4,
                            child: Image.network(
                              decodedUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return const Text('GAMBAR TIDAK DITEMUKAN!');
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Text(keterangan, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    ],
                  ),
                ),
              ),
            ]
          ),
        ],
      ),
    );
  }
}
