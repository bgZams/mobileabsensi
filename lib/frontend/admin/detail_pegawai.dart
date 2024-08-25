import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailPage extends StatefulWidget {
  final String idPegawai;

  const DetailPage({Key? key, required this.idPegawai}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final response = await http.get(
      Uri.parse('https://simpel.pasamanbaratkab.go.id/api_android/simaya/getByIdUser.php?id_user=${widget.idPegawai}'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        user = jsonResponse['data'][0];
      });
    } else {
      throw Exception('Failed to load user details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pegawai'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfo('Nama Lengkap', user!['nama_lengkap']),
                      const SizedBox(height: 16),
                      _buildUserInfo('Username', user!['username']),
                      _buildUserInfo('Jabatan', user!['data_jabatan']),
                      _buildUserInfo('Instansi', user!['nama_instansi']),
                      _buildUserInfo('Status', user!['nama_status']),
                      const SizedBox(height: 16),
                      const Text(
                        'Atasan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildUserInfo('Nama', user!['nama_atasan']),
                      _buildUserInfo('NIP', user!['nip_atasan']),
                      _buildUserInfo('Jabatan', user!['jabatan_atasan']),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfo(String label, String? value) {
    return Text('$label: ${value ?? 'N/A'}');
  }
}
