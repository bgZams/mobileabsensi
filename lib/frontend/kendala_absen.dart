import 'package:flutter/material.dart';

class KendalaAbsen extends StatefulWidget {
  const KendalaAbsen({Key? key}) : super(key: key);

  @override
  State<KendalaAbsen> createState() => _KendalaAbsenState();
}

class _KendalaAbsenState extends State<KendalaAbsen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),
        title: const Text('Kendala',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
         leading: IconButton(
              icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}