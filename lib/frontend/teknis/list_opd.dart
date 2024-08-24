import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListOPD extends StatefulWidget {
  const ListOPD({Key? key}) : super(key: key);

  @override
  State<ListOPD> createState() => _ListOPDState();
}

class _ListOPDState extends State<ListOPD> {
  late Future<List<OPD>> futureOPDList;

  @override
  void initState() {
    super.initState();
    futureOPDList = fetchOPDList();
  }

  Future<List<OPD>> fetchOPDList() async {
    final response = await http.get(Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/get_admin_opd.php'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body)['data'];

      // Filter the list to exclude items with id_server null
      List filteredJsonResponse = jsonResponse.where((data) => data['id_server'] != null).toList();

      return filteredJsonResponse.map((data) => OPD.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load OPD list');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 60, 129),

        title: const Text('List OPD',style: TextStyle(color: Colors.white),),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 228, 224, 224),
        child: FutureBuilder<List<OPD>>(
          future: futureOPDList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<OPD>? opdList = snapshot.data;
              return ListView.builder(
                itemCount: opdList!.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    elevation: 3,
                    shape: Border.all(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Instansi'),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  ': ${opdList[index].namaInstansi}',
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Admin'),
                              const SizedBox(width: 30,),
                              Text(': ${opdList[index].name}')
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Server'),
                              const SizedBox(width: 30,),
                              Text(': ${opdList[index].idServer.toString()}')
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class OPD {
  final int no;
  final String? idServer;
  final String namaInstansi;
  final String idUser;
  final String username;
  final String name;

  OPD({
    required this.no,
    this.idServer,
    required this.namaInstansi,
    required this.idUser,
    required this.username,
    required this.name,
  });

  factory OPD.fromJson(Map<String, dynamic> json) {
    return OPD(
      no: json['no'],
      idServer: json['id_server'],
      namaInstansi: json['nama_instansi'],
      idUser: json['id_user'],
      username: json['username'],
      name: json['name'],
    );
  }
}
