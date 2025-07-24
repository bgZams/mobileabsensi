import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class DetailPengajuanIzin extends StatefulWidget {
  final Map<String, dynamic> data;
  final int noUrut;

  const DetailPengajuanIzin({
    super.key, 
    required this.data, 
    required this.noUrut
  });

  @override
  DetailPengajuanIzinState createState() => DetailPengajuanIzinState();
}

class DetailPengajuanIzinState extends State<DetailPengajuanIzin> {
  late String baseUrl;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    baseUrl = SpUtil.getString("url") ?? "";
    _initializeImageUrl();
  }

  Future<bool> checkUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeImageUrl() async {
    if (widget.data['file'] != null && widget.data['file'].isNotEmpty) {
      String url1 = 'http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/public/foto/${widget.data['file']}';
      String url2 = 'https://mobileabsensi.pasamanbaratkab.go.id/foto/${widget.data['file']}';
 
      if (await checkUrl(url1)) {
        setState(() {
          imageUrl = url1;
        });
      } else if (await checkUrl(url2)) {
        setState(() {
          imageUrl = url2;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String jenisStatus;
    String statusApproval;
    Color iconColor;

    switch (widget.data['status_approval'].toString()) {
      case '1':
        statusApproval = 'Diajukan';
        iconColor = Colors.orange;
        break;
      case '2':
        statusApproval = 'Disetujui';
        iconColor = Colors.green;
        break;
      case '3':
        statusApproval = 'Ditolak';
        iconColor = Colors.red;
        break;
      default:
        statusApproval = 'Diajukan';
        iconColor = Colors.black;
    }

    switch (widget.data['jenis_approval'].toString()) {
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

    var jamMasuk = DateFormat('EEEE, dd/MM/yyyy H:i:s', 'id')
                    .format(DateTime.parse(widget.data['timestamp']));
                    print(widget.data['created_at']);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
     
       
      body: Stack(
        children: [
          // Background header that extends beyond what's visible
          WidgetNavbar(title: 'Detail Izin'),

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
                  child:   Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  _buildTableRow( 
                    'Tgl Pengajuan',
                    ': $jamMasuk' != '' ? ': $jamMasuk' : '',
                  ),
                  _buildTableRow(
                    'Tgl Izin',
                    ': ${DateFormat('EEEE, dd/MM/yyyy', 'id')
                    .format(DateTime.parse(widget.data['tgl_group']))}',
                  ),
                  _buildTableRow(
                    'Durasi',
                    ': ${widget.data['durasi'].toString()} Hari',
                  ),
                  _buildTableRow('Jenis Izin', ': $jenisStatus'),
                  _buildTableRow(
                    'Keterangan', 
                    ': ${widget.data['keterangan']}'
                  ),
                  _buildStatusApprovalRow(statusApproval, iconColor),
                ],
              ),
              const SizedBox(height: 16),
              if (imageUrl != null)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Tidak ada file tersedia',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
              )
            ]
          )
        ]
      )
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            value,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  TableRow _buildStatusApprovalRow(String statusApproval, Color iconColor) {
    return TableRow(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: ElevatedButton(
            onPressed: () {
              // Kode yang akan dijalankan saat tombol ditekan
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(iconColor),
            ),
            child: Text(
              statusApproval,
              style: const TextStyle(
                color: Color.fromARGB(255, 228, 243, 255),
              ),
            ),
          ),
        ),
      ],
    );
  }
}