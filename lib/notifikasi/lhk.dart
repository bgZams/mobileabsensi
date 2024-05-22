import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseLhk {
  Future addLhk(Map<String, dynamic> lhk) async {
    return await FirebaseFirestore.instance
        .collection("laporan_harian")
        .doc()
        .set(lhk);
  }
}
