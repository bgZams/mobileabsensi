import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:convert';
import 'package:sp_util/sp_util.dart';

class KonfirmasiIzin extends StatefulWidget {
  const KonfirmasiIzin({super.key});

  @override
  State<KonfirmasiIzin> createState() => _KonfirmasiIzinState();
}

class _KonfirmasiIzinState extends State<KonfirmasiIzin>
    with TickerProviderStateMixin {
      bool isLoading = false;
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
  @override
void initState() {
  super.initState();
  _controller = TabController(length: list.length, vsync: this);
  // Hapus listener fetch data di sini jika tidak diperlukan setiap ganti tab
  // karena data izin dan LHK sudah diambil sekaligus di awal
  _controller?.addListener(() {
    if (_controller!.indexIsChanging) { // Hanya picu saat tab benar-benar berubah
      setState(() {
        selectedIndex = _controller!.index;
      });
    }
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
  // Cegah double loading
  if (isLoading) return;

  setState(() {
    isLoading = true;
  });

  if (idUser == null || url == null || idUser!.isEmpty || url!.isEmpty) {
    setState(() => isLoading = false);
    return;
  }

  try {
    // MENJALANKAN DUA REQUEST SEKALIGUS (PARALEL)
    final results = await Future.wait([
      http.get(Uri.parse('$url/api/riwayat-izin/notif/$idUser'), headers: {'Accept': 'application/json'}),
      http.get(Uri.parse('$url/api/riwayat-lhk/notif/$idUser'), headers: {'Accept': 'application/json'}),
    ]);

    final resIzin = results[0];
    final resLhk = results[1];
    // Proses data secara lokal dulu tanpa setState
    List<dynamic> tempIzin = [];
    List<dynamic> tempLhk = [];

    if (resIzin.statusCode == 200) {
      tempIzin = json.decode(resIzin.body)['data'] ?? [];
    }

    if (resLhk.statusCode == 200) {
      tempLhk = json.decode(resLhk.body)['data'] ?? [];
    }

    // Hanya satu kali rebuild untuk menampilkan semua data
    if (mounted) {
      setState(() {
        _riwayatIzin = tempIzin;
        _riwayatLhk = tempLhk;
        isLoading = false;
      });
    }
  } catch (error) {
    debugPrint('Error: $error');
    if (mounted) setState(() => isLoading = false);
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
          selectedIndex = 1;
          _controller?.animateTo(1);
        });
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('LHK berhasil ditolak')),
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
    finally {
      setState(() {
        isLoading = false; // Nonaktifkan skeleton
      });
    }
  }

  Future<void> _sendAcception(int id, int idUser) async {
  try {
    var response = await http.put(
      Uri.parse('$url/api/lhk/terima/$id'),
      body: {
        'id_user': idUser.toString(),
        'pesan': 'Laporan diterima',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        selectedIndex = 1;
        _controller?.animateTo(1);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }

      _fetchData();
    }
  } catch (e) {
    debugPrint('Error: $e');
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
        WidgetNavbar(title: 'Riwayat Konfirmasi',),
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
      ? (isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text('Tidak ada data Izin')))
      : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _riwayatIzin.length,
          itemBuilder: (context, index) =>
              _buildIzinItem(context, _riwayatIzin[index]),
        ))
  : (_riwayatLhk.isEmpty
      ? (isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text('Tidak ada data Lhk')))
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
    String jenisStatus = _getStatus(izin['status']);
  
    return Skeletonizer(
      enabled: isLoading,
      child: Card(
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
            child: Skeleton.replace(
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
        ),
      ),
    );
  }

  Widget _buildLhkItem(BuildContext context, dynamic lhk) {

  return Skeletonizer(
    enabled: isLoading,
    child: Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lhk['nama_lengkap'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Jam Selesai: ${lhk['jamselesai'].toString()}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kegiatan: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Flexible(
                            child: Text(
                              lhk['rincian_kegiatan'].toString(),
                              style: TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Skeleton.replace(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _sendAcception(lhk['id'], lhk['id_user']);
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
                          fontSize: 16,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getStatus(int statusCode) {
    switch (statusCode) {
      case 2:
        return 'Dinas Luar';
      case 3:
        return 'Izin';
      case 4:
        return 'Sakit';
      case 5:
        return 'IDLK';
      case 6:
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
