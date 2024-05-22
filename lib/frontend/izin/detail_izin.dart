import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sp_util/sp_util.dart';

class DetailPengajuanIzin extends StatefulWidget {
  final Map<String, dynamic> data;
  final int noUrut; // Perubahan pada tipe data parameter noUrut

  const DetailPengajuanIzin(
      {Key? key, required this.data, required this.noUrut})
      : super(key: key);

  @override
  _DetailPengajuanIzinState createState() => _DetailPengajuanIzinState();
}

class _DetailPengajuanIzinState extends State<DetailPengajuanIzin> {
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    baseUrl = SpUtil.getString("url") ?? ""; // Ambil URL dasar dari SpUtil
  }

  @override
  Widget build(BuildContext context) {
    // Gabungkan URL dasar dengan jalur file
    String imageUrl =
        widget.data['file'] != null && widget.data['file'].isNotEmpty
            ? '$baseUrl/${widget.data['file']}'
            : '';
    String jenisStatus;
    String statusApproval;
    IconData iconData;
    Color iconColor;

    switch (widget.data['status_approval'].toString()) {
      case '1':
        iconData = FontAwesomeIcons.stopwatch;
        iconColor = Colors.orange;
        break;
      case '2':
        iconData = Icons.check_outlined;
        iconColor = Colors.green;
        break;
      case '3':
        iconData = Icons.close;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.error;
        iconColor = Colors.black;
    }
    switch (widget.data['status_approval'].toString()) {
      case '1':
        statusApproval = 'Diajukan';

        break;
      case '2':
        statusApproval = 'Disetujui';

        break;
      case '3':
        statusApproval = 'Ditolak';

        break;
      default:
        statusApproval = 'Diajukan';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan Izin'),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                    ': ${widget.data['timestamp_masuk']}' != null
                        ? ': ${widget.data['timestamp_masuk'].toString()}'
                        : '',
                  ),
                  _buildTableRow(
                    'Tgl Izin',
                    ': ${widget.data['tgl_mulai'].toString()} ',
                  ),
                  _buildTableRow(
                    'Durasi',
                    ': ${widget.data['durasi'].toString()} Hari',
                  ),
                  _buildTableRow('Jenis Izin', ': ${jenisStatus}'),
                  _buildTableRow(
                      'Keterangan', ': ${widget.data['keterangan']}'),
                  _buildStatusApprovalRow(statusApproval, iconColor),
                ],
              ),
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.fitWidth,
                      width: MediaQuery.of(context).size.width,
                    )
                  : const Text('Tidak ada file tersedia'),
            ],
          ),
        ),
      ),
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
              backgroundColor: MaterialStateProperty.all<Color>(iconColor),
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
