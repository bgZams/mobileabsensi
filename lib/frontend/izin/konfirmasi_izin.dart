import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class KonfirmasiIzin extends StatefulWidget {
  const KonfirmasiIzin({Key? key}) : super(key: key);

  @override
  State<KonfirmasiIzin> createState() => _KonfirmasiIzinState();
}

class _KonfirmasiIzinState extends State<KonfirmasiIzin>
    with TickerProviderStateMixin {
  List<dynamic> _riwayatIzin = [];
  List<dynamic> _riwayatLhk = [];
  String? url;
  String? idUser;
  TabController? _controller;
  int selectedIndex = 0;

  List<Widget> list = [
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.envelope,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          Text("Izin"),
        ],
      ),
    ),
    const Tab(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.listCheck,
            color: Colors.yellow,
          ),
          SizedBox(width: 8),
          Text("LHK"),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: list.length, vsync: this);
    _controller?.addListener(() {
      setState(() {
        selectedIndex = _controller!.index;
      });
      _fetchData();

      print("Selected Index: ${_controller?.index}");
    });
    initializePreferences();
  }

  Future<void> initializePreferences() async {
    await SpUtil.getInstance();
    setState(() {
      url = SpUtil.getString("url");
      idUser = SpUtil.getString("id_user");
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (idUser == null || url == null || idUser!.isEmpty || url!.isEmpty) {
      debugPrint('Error: idUser or url is empty');
      return;
    }

    try {
      final responseIzin = await http.get(
        Uri.parse('$url/api/riwayat-izin/notif/$idUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final responseLhk = await http.get(
        Uri.parse('$url/api/riwayat-lhk/notif/$idUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (responseIzin.statusCode == 200) {
        _processDataIzin(responseIzin);
      } else {
        throw Exception('Failed to load data Izin');
      }
      if (responseLhk.statusCode == 200) {
        _processDataLhk(responseLhk);
      } else {
        throw Exception('Failed to load data LHK');
      }
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  void _processDataIzin(http.Response response) {
    setState(() {
      _riwayatIzin = json.decode(response.body)['data'];
    });
  }

  void _processDataLhk(http.Response response) {
    setState(() {
      _riwayatLhk = json.decode(response.body)['data'];
    });
  }

  Future<void> _sendRejection(int id, String alasan) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/lhk/tolak/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'alasan': alasan}),
      );

      if (response.statusCode == 200) {
        setState(() {
          selectedIndex = 1; // Set index to LHK tab
          _controller?.animateTo(1); // Move to LHK tab
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil ditolak')),
        );

        _refreshData();
      } else {
        throw Exception('Failed to reject izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _sendAcception(int id) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/lhk/terima/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          selectedIndex = 1; // Set index to LHK tab
          _controller?.animateTo(1); // Move to LHK tab
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        _fetchData();
      } else {
        throw Exception('Gagal menyetujui izin');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Izin'),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/home-page'),
        ),
        bottom: TabBar(
          controller: _controller,
          tabs: list,
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          _riwayatIzin.isEmpty
              ? const Center(child: Text('No data found'))
              : ListView.builder(
                  itemCount: _riwayatIzin.length,
                  itemBuilder: (context, index) =>
                      _buildIzinItem(context, _riwayatIzin[index]),
                ),
          _riwayatLhk.isEmpty
              ? const Center(child: Text('No data found'))
              : ListView.builder(
                  itemCount: _riwayatLhk.length,
                  itemBuilder: (context, index) =>
                      _buildLhkItem(context, _riwayatLhk[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildIzinItem(BuildContext context, dynamic izin) {
    String jenisStatus = _getStatus(izin['status'].toString());

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: ListTile(
        title: Text(izin['nama_lengkap'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $jenisStatus'),
            Text('Tanggal Pengajuan: \n ${izin['timestamp_masuk']}'),
            Text('Durasi: ${izin['durasi']} Hari'),
          ],
        ),
        trailing: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/detail-konfirmasi-izin',
                arguments: izin['id_approval']);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 160, 212, 255),
            ),
            child: const Text(
              'Detail',
              style: TextStyle(
                color: Color.fromARGB(255, 3, 117, 210),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLhkItem(BuildContext context, dynamic lhk) { 
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: ListTile(
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Ubah alignment menjadi sebelah kiri
          children: [
            Text(
              lhk['nama_lengkap'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Ubah alignment menjadi sebelah kiri
                  children: [
                    Text('Jam Mulai: ${lhk['jammulai'].toString()}'),
                    Text('Jam Selesai: ${lhk['jamselesai'].toString()}'),
                    Text('Kegiatan: ${lhk['rincian_kegiatan']}'),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    _sendAcception(lhk['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color.fromARGB(255, 161, 255, 156),
                    ),
                    child: const Text(
                      'Terima',
                      style: TextStyle(
                        color: Color.fromARGB(255, 8, 153, 0),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    _showRejectDialog(lhk['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color.fromARGB(255, 255, 160,
                          160), // Changed color to indicate a different action
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(
                          color: Color.fromARGB(255, 233, 3, 3),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatus(String statusCode) {
    switch (statusCode) {
      case '2':
        return 'Dinas Luar';
      case '3':
        return 'Izin';
      case '4':
        return 'Sakit';
      case '5':
        return 'IDLK';
      case '6':
        return 'Cuti';
      default:
        return 'Belum Disetujui';
    }
  }

  void _showRejectDialog(int id) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: controller,
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
                String alasan = controller.text;
                if (alasan.isNotEmpty) {
                  _sendRejection(id, alasan);
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
}
