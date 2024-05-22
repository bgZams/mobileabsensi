import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

class NotifikasiLaporanHarian extends StatefulWidget {
  const NotifikasiLaporanHarian({super.key});

  @override
  State<NotifikasiLaporanHarian> createState() =>
      _NotifikasiLaporanHarianState();
}

class _NotifikasiLaporanHarianState extends State<NotifikasiLaporanHarian> {
  TextEditingController idUser = TextEditingController();
  TextEditingController idPimpinan = TextEditingController();
  final firebaseLaporan = FirebaseDatabase.instance;
  var l;
  var g;
  var k;
  @override
  Widget build(BuildContext context) {
    final datalaporan = firebaseLaporan.ref().child('laporan_harian');

    return Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi Laporan Harian'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              FirebaseAnimatedList(
                query: datalaporan,
                shrinkWrap: true,
                itemBuilder: (context, snapshot, animation, index) {
                  var v = snapshot.value
                      .toString(); // {subtitle: webfun, title: subscribe}

                  g = v.replaceAll(RegExp("{|}|subtitle: |title: "),
                      ""); // webfun, subscribe
                  g.trim();

                  l = g.split(','); // [webfun,  subscribe}]

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        k = snapshot.key;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Container(
                              decoration: BoxDecoration(border: Border.all()),
                              child: TextField(
                                controller: idUser,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: 'title',
                                ),
                              ),
                            ),
                            content: Container(
                              decoration: BoxDecoration(border: Border.all()),
                              child: TextField(
                                controller: idPimpinan,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: 'sub title',
                                ),
                              ),
                            ),
                            actions: <Widget>[
                              MaterialButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                color: const Color.fromARGB(255, 0, 22, 145),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              MaterialButton(
                                onPressed: () async {
                                  await upd();
                                  Navigator.of(ctx).pop();
                                },
                                color: const Color.fromARGB(255, 0, 22, 145),
                                child: const Text(
                                  "Update",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor: Colors.indigo[100],
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 255, 0, 0),
                            ),
                            onPressed: () {
                              datalaporan.child(snapshot.key!).remove();
                            },
                          ),
                          title: Text(
                            l[1],
                            // 'dd',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            l[0],
                            // 'dd',

                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ));
  }

  // Update Data Di Firebase [OK]
  upd() async {
    DatabaseReference ref1 = FirebaseDatabase.instance.ref("laporan_harian/$k");
    await ref1.update(
        {'id_user': idUser.text, 'id_atasan': idPimpinan.text, 'id_status': 1});
  }
}
