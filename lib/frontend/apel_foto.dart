import 'package:flutter/material.dart';

class ApelFoto extends StatelessWidget {

  const ApelFoto({Key? key, required idApel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        child: Image.network(''),
      ),
    );
  }
}
