import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileabsensi/widget/widget_navbar.dart';

class ListOPD extends StatefulWidget {
  const ListOPD({super.key});

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
    Size size = MediaQuery.of(context).size;

    return Scaffold(
     
       
      body: Stack(
        children: [
          // Background header that extends beyond what's visible
          WidgetNavbar(title: 'List OPD'),

          // Scrollable content area taking most of the screen
          Column(
            children: [
              // Spacer to push content down to create overlap
              SizedBox(height: size.height * 0.15),

              // Content area
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
                  child:   FutureBuilder<List<OPD>>(
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
              ),
            ]
          )
        ]
      )
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
