import 'package:flutter/material.dart';

class ApelFoto extends StatelessWidget {

  const ApelFoto({super.key, required idApel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
        title: const Text('Lihat Foto',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
         leading: IconButton(
              icon: const Icon(Icons.arrow_back,color: Colors.white,),
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
