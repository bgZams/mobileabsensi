import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sp_util/sp_util.dart';

class DetailKonfirmasiIzinAtasan extends StatefulWidget {
  const DetailKonfirmasiIzinAtasan({Key? key}) : super(key: key);

  @override
  State<DetailKonfirmasiIzinAtasan> createState() =>
      _DetailKonfirmasiIzinAtasanState();
}

class _DetailKonfirmasiIzinAtasanState
    extends State<DetailKonfirmasiIzinAtasan> {
  List<dynamic> _riwayatIzin = [];
  var url = SpUtil.getString("url");
  late int idApproval;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        setState(() {
          idApproval = args as int;
        });
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      http.Response riwayatIzinResponse = await http.get(
        Uri.parse('$url/api/riwayat-izin/konfirmasi/$idApproval'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (riwayatIzinResponse.statusCode == 200) {
        setState(() {
          _riwayatIzin = json.decode(riwayatIzinResponse.body)['data'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  void _showRejectDialog(int idApproval) {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Masukkan alasan"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kirim'),
              onPressed: () {
                String alasan = _controller.text;
                if (alasan.isNotEmpty) {
                  _sendRejection(idApproval, alasan);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alasan tidak boleh kosong')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendRejection(int idApproval, String alasan) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/riwayat-izin/tolak/$idApproval'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'alasan': alasan}),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/konfirmasi-izin');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil ditolak')),
        );
        _fetchData(); // Refresh data
      } else {
        throw Exception('Failed to reject izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _sendAcception(int idApproval) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/riwayat-izin/terima/$idApproval'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/konfirmasi-izin');

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        _fetchData(); // Refresh data
      } else {
        throw Exception('Gagal menyetujui izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Izin'),
      ),
      body: _riwayatIzin.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _riwayatIzin.length,
              itemBuilder: (context, index) {
                var izin = _riwayatIzin[index];
                String jenisStatus;
                switch (izin['status'].toString()) {
                  case '2':
                    jenisStatus = 'Dinas Luar';
                    break;
                  case '3':
                    jenisStatus = 'Izin';
                    break;
                  case '4':
                    jenisStatus = 'Sakit';
                    break;
                  case '5':
                    jenisStatus = 'IDLK';
                    break;
                  case '6':
                    jenisStatus = 'Cuti';
                    break;
                  default:
                    jenisStatus = 'Belum Disetujui';
                }
                String imageUrl =
                    izin['file'] != null && izin['file'].isNotEmpty
                        ? '$url/${izin['file']}'
                        : '';
                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                _sendAcception(izin['id_approval']);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13, horizontal: 28),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      const Color.fromARGB(255, 161, 255, 156),
                                ),
                                child: const Text(
                                  'Terima',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 8, 153, 0),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            InkWell(
                              onTap: () {
                                _showRejectDialog(izin['id_approval']);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13, horizontal: 28),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      const Color.fromARGB(255, 255, 160, 160),
                                ),
                                child: const Text(
                                  'Tolak',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 233, 3, 3),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: Text(izin['nama_lengkap'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $jenisStatus'),
                            Text(
                                'Tanggal Pengajuan: \n ${izin['timestamp_masuk']}'),
                            Text('Durasi: ${izin['durasi']} Hari'),
                          ],
                        ),
                      ),
                      Container(
                        color: const Color.fromARGB(255, 255, 7, 7),
                        width: MediaQuery.of(context).size.width,
                        height: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      imageUrl.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.fitWidth,
                                width: MediaQuery.of(context).size.width,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('Gagal memuat gambar');
                                },
                              ),
                            )
                          : const Text('Tidak ada file tersedia'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
