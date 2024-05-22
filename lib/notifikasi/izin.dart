import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseIzin {
  Future addIzin(Map<String, dynamic> izin) async {
    return await FirebaseFirestore.instance.collection("izin").doc().set(izin);
  }
}
