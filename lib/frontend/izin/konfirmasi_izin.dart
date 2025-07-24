import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class KonfirmasiIzin extends StatefulWidget {
  const KonfirmasiIzin({super.key});

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
  bool showFullText = false;

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
        throw Exception('Tidak ada data LHK ditemukan');
      }
      if (responseLhk.statusCode == 200) {
        _processDataLhk(responseLhk);
      } else {
        throw Exception('Tidak ada data LHK ditemukan');
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
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Izin berhasil ditolak')),
          );
        }

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

  Future<void> _sendAcception(id, idUser, status) async {
    try {
      var response = await http.put(
        Uri.parse('$url/api/lhk/terima/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'id_user':idUser,
          'pesan':'Izin diterima',
          'status': status,
        }
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        
        setState(() {
          selectedIndex = 1; // Set index to LHK tab
          _controller?.animateTo(1); // Move to LHK tab
        });
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
        }
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
        WidgetNavbar(title: 'Riwayat Laporan Harian',),
          Column(
            children: [
              SizedBox(height: size.height * 0.15),
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
                child: ListView(
               children: [ TabBar(
                 controller: _controller,
                 tabs: list,
                 indicatorColor: Colors.green,
                 dividerColor: Colors.blue,
                 unselectedLabelColor: Colors.grey[500],
                 labelColor: Colors.black,
               ),
               SizedBox(height: 20,),
                selectedIndex == 0
                    ? (_riwayatIzin.isEmpty
                        ? const Center(child: Text('Tidak ada data Izin'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _riwayatIzin.length,
                            itemBuilder: (context, index) =>
                                _buildIzinItem(context, _riwayatIzin[index]),
                          ))
                    : (_riwayatLhk.isEmpty
                        ? const Center(child: Text('Tidak ada data Lhk'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _riwayatLhk.length,
                            itemBuilder: (context, index) =>
                                _buildLhkItem(context, _riwayatLhk[index]),
                          )),
               ]
                      ),
                      ),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIzinItem(BuildContext context, dynamic izin) {
    String jenisStatus = _getStatus(izin['status'].toString());
  
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(izin['nama_lengkap'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $jenisStatus'),
            Text('Tanggal Pengajuan: \n${DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .format(DateTime.parse(izin['created_at']))}'),
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
          Map<String, bool> expandedItems = {};

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
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jam Mulai: ${lhk['jammulai'].toString()}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Jam Selesai: ${lhk['jamselesai'].toString()}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),

// Kemudian gunakan implementasi berikut
Theme(
  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Kegiatan: ',
        style: TextStyle(fontSize: 14),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                // Gunakan ID unik untuk setiap item (misalnya id dari lhk atau indeks dalam loop)
                String itemId = lhk['id'].toString(); // atau gunakan indeks jika dalam loop
                
                setState(() {
                  // Toggle status hanya untuk item spesifik ini
                  expandedItems[itemId] = !(expandedItems[itemId] ?? false);
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lhk['rincian_kegiatan'].toString(),
                      style: TextStyle(fontSize: 14),
                      maxLines: (expandedItems[lhk['id'].toString()] ?? false) ? null : 1,
                      overflow: (expandedItems[lhk['id'].toString()] ?? false) ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (lhk['rincian_kegiatan'].toString().length > 50)
                    Icon(
                      (expandedItems[lhk['id'].toString()] ?? false) ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 18,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
        ],
      ),
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
                    var id = lhk['id'];
                    var idUser = lhk['id_user'];
                    var status = lhk['status'];
                    _sendAcception(id, idUser, status);
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
