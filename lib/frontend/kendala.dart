import 'package:flutter/material.dart';

class Kendala extends StatefulWidget {
  const Kendala({super.key});

  @override
  State<Kendala> createState() => _KendalaState();
}

class _KendalaState extends State<Kendala> {

  @override
  void initState() {
    super.initState();
    // You can initialize or fetch data here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 67, 60, 130),
        title: const Text('Kendala Absen Online',style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        elevation: 4,
         leading: IconButton(
              icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
