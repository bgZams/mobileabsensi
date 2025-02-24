import 'package:flutter/material.dart';
import 'dart:convert'; // for JSON decoding
import 'package:http/http.dart' as http;

class Pegawai extends StatefulWidget {
  const Pegawai({super.key});

  @override
  State<Pegawai> createState() => _PegawaiState();
}

class _PegawaiState extends State<Pegawai> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.post(
        Uri.parse(
            'https://simpel.pasamanbaratkab.go.id/api_android/simaya/get_alluserbyadmin.php'),
        body: {'username': 'admin.diskominfo'});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        users = jsonResponse['data'];
        filteredUsers = users;
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  void filterUsers(String query) {
    setState(() {
      filteredUsers = users
          .where((user) =>
              user['nama_lengkap'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Pegawai'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Cari Pegawai',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) => filterUsers(query),
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      if (user['groups'] != "3") {
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['nama_lengkap'],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(user['data_jabatan']),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        var idPegawai = user['id_user'];
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/absen/$idPegawai',
                                          arguments: idPegawai,
                                        );
                                      },
                                      child: const Text('Absen'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        var idPegawai = user['id_user'];
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/lhk/$idPegawai',
                                          arguments: idPegawai,
                                        );
                                      },
                                      child: const Text('LHK'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        var idPegawai = user['id_user'];
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/detail/$idPegawai',
                                          arguments: idPegawai,
                                        );
                                      },
                                      child: const Text('Detail'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return null;
                    }),
          ),
        ]));
  }
}
