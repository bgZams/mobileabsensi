import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sp_util/sp_util.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<Map<String, dynamic>> wifiData = [];
  bool _isLoading = false;
  var idUser = SpUtil.getString("id_user");
  DateTime? lastFetchTime;

  @override
  void initState() {
    super.initState();
  }

  
  void _startLoading() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ambildata();
    } catch (error) {
      if (kDebugMode) {
        print("Error: $error");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          Container(
            alignment: Alignment.center,
            height: size.height * .2,
            decoration: const BoxDecoration(
              image: DecorationImage(
                alignment: Alignment.topCenter,
                image: AssetImage('assets/images/profil.png'),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: 90,
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.edit_square,
                          color: Colors.pink,
                          size: 24.0,
                          semanticLabel:
                              'Text to announce in accessibility modes',
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(' Detail Pengguna',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ],
                    ),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      border: TableBorder.all(
                          color: const Color.fromARGB(0, 255, 255, 255)),
                      children: [
                        TableRow(children: [
                          const TableCell(child: Text("ID Server")),
                          TableCell(
                            child: Text(
                                " Server ${SpUtil.getString('id_server') ?? ''}"),
                          ),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("ID User")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("id_user") ?? ''}")),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("Username")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("username") ?? ''}")),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("Nama Lengkap")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("nama_lengkap") ?? ''}")),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("Nama Instansi")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("nama_instansi") ?? ''}")),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.edit_square,
                          color: Colors.pink,
                          size: 24.0,
                          semanticLabel:
                              'Text to announce in accessibility modes',
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(' Detail Atasan',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ],
                    ),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      border: TableBorder.all(
                          color: const Color.fromARGB(0, 255, 255, 255)),
                      children: [
                        TableRow(children: [
                          const TableCell(child: Text("Nama")),
                          TableCell(
                            child: Text(
                                " ${SpUtil.getString('nama_atasan') ?? ''}"),
                          ),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("NIP")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("nip_atasan") ?? ''}")),
                        ]),
                        TableRow(children: [
                          const TableCell(child: Text("Jabatan")),
                          TableCell(
                              child: Text(
                                  " ${SpUtil.getString("jabatan_atasan") ?? ''}")),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.sync_rounded),
              label: Text(
                _isLoading ? 'Loading...' : 'Syncron Data',
                style: const TextStyle(fontSize: 14),
              ),
              onPressed: _isLoading ? null : _startLoading,
              style: ElevatedButton.styleFrom(fixedSize: const Size(140, 40)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> ambildata() async {
    setState(() {
      _isLoading = true;
    });

    // Memeriksa apakah telah lewat 1 menit sejak pengambilan data terakhir
    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) <
            const Duration(minutes: 1)) {
      setState(() {
        _isLoading = false;
      });
      return QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: "Syncron data minimal 1 menit sekali!",
      );
    }

    try {
      http.Response datapegawai = await http.get(
        Uri.parse(
            'https://simpel.pasamanbaratkab.go.id/api_android/simaya/getByIdUser.php?id_user=$idUser'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json'
        },
      );

      var responseData = json.decode(datapegawai.body);
      var user = responseData['data'];
      for (var userData in user) {
        SpUtil.putString('id_server', userData['id_server']);
        SpUtil.putString('id_user', userData['id_user']);
        SpUtil.putString('id_instansi', userData['id_instansi']);
        SpUtil.putString('id_groups', userData['id_groups'] ?? '');
        SpUtil.putString('id_user_pimpinan', userData['id_user_parent'] ?? '');
        SpUtil.putString(
            'id_admin_instansi', userData['id_admin_instansi'] ?? '');
        SpUtil.putString('id_pimpinan', userData['id_pimpinan'] ?? '');
        String usernameString = userData['username'];
        SpUtil.putString('username', usernameString.replaceAll('"', ''));
        String userAdminString = userData['username_admin'];
        SpUtil.putString('username_admin', userAdminString.replaceAll('"', ''));
        String namaLengkap = userData['nama_lengkap'];
        SpUtil.putString('nama_lengkap', namaLengkap.replaceAll('"', ''));
        SpUtil.putString('nama_instansi', userData['nama_instansi'] ?? '');
        SpUtil.putString('nama_atasan', userData['nama_atasan'] ?? '');
        SpUtil.putString('nip_atasan', userData['nip_atasan'] ?? '');
        SpUtil.putString('jabatan_atasan', userData['jabatan_atasan'] ?? '');
        SpUtil.putString('url', userData['url'] ?? '');
      }

      lastFetchTime = DateTime.now();

      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: "Data berhasil diperbarui!!",
      );

      // Tampilkan dialog sukses
    } catch (e) {
      // Tangani kesalahan
      print('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }
}
