import 'package:flutter/material.dart';

class LihatSpt extends StatelessWidget {
  final String imageUrl;

  const LihatSpt({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    String decodedUrl = Uri.decodeComponent(imageUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Foto'),
        elevation: 4,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Image.network(
          decodedUrl,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return const Text('GAMBAR TIDAK DITEMUKAN!');
          },
        ),
      ),
    );
  }
}
