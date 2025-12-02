import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:mobileabsensi/widget/widget_navbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sp_util/sp_util.dart';
import 'package:http/http.dart' as http;

class DetailPengajuanIzin extends StatefulWidget {
  final Map<String, dynamic> data;
  final int noUrut;

  const DetailPengajuanIzin({
    super.key,
    required this.data,
    required this.noUrut,
  });

  @override
  DetailPengajuanIzinState createState() => DetailPengajuanIzinState();
}

class DetailPengajuanIzinState extends State<DetailPengajuanIzin> {
  // Warna Tema Utama
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlueBg = const Color(0xFFE3F2FD);
  final Color labelColor = Colors.grey.shade600;
  final Color contentColor = Colors.black87;

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
      String url1 =
          'http://mobileabsensi${int.tryParse(SpUtil.getString('id_server') ?? '0')}.pasamanbaratkab.go.id/api_android_v2/${widget.data['file']}';
      String url2 =
          'https://mobileabsensi.pasamanbaratkab.go.id/foto/${widget.data['file']}';
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

  Future<void> _saveImage(BuildContext context, String imageUrl) async {
    String? message;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh gambar');
      }
      final dir = await getTemporaryDirectory();
      final filename = '${dir.path}/${imageUrl.split('/').last}';
      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);
      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Gambar berhasil disimpan';
      }
    } catch (e) {
      message = 'Gagal menyimpan: $e';
    }

    if (message != null) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: message.contains('Gagal') ? Colors.red : Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Logic Data ---
    String statusApproval;
    Color statusColor;
    Color statusBgColor;

    switch (widget.data['status_approval'].toString()) {
      case '1':
        statusApproval = 'Menunggu Persetujuan';
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade50;
        break;
      case '2':
        statusApproval = 'Disetujui';
        statusColor = Colors.green.shade800;
        statusBgColor = Colors.green.shade50;
        break;
      case '3':
        statusApproval = 'Ditolak';
        statusColor = Colors.red.shade800;
        statusBgColor = Colors.red.shade50;
        break;
      default:
        statusApproval = 'Diajukan';
        statusColor = Colors.blue.shade800;
        statusBgColor = Colors.blue.shade50;
    }

    String jenisStatus;
    IconData jenisIcon;
    switch (widget.data['jenis_approval'].toString()) {
      case '2':
        jenisStatus = 'Dinas Luar';
        jenisIcon = Icons.business_center_outlined;
        break;
      case '3':
        jenisStatus = 'Izin';
        jenisIcon = Icons.assignment_turned_in_outlined;
        break;
      case '4':
        jenisStatus = 'Sakit';
        jenisIcon = Icons.local_hospital_outlined;
        break;
      case '5':
        jenisStatus = 'IDLK';
        jenisIcon = Icons.location_city_outlined;
        break;
      case '6':
        jenisStatus = 'Cuti';
        jenisIcon = Icons.beach_access_outlined;
        break;
      default:
        jenisStatus = '-';
        jenisIcon = Icons.help_outline;
    }

    var tglPengajuan = DateFormat('dd MMM yyyy', 'id')
        .format(DateTime.parse(widget.data['created_at']));
    var tglIzin = DateFormat('EEEE, dd MMMM yyyy', 'id')
        .format(DateTime.parse(widget.data['tgl_group']));

    Size size = MediaQuery.of(context).size;

    // --- UI Build ---
    return Scaffold(
      backgroundColor: primaryBlue, // Background biru agar menyatu dengan navbar
      body: Stack(
        children: [
          WidgetNavbar(title: 'Detail Pengajuan'),
          Column(
            children: [
              SizedBox(height: size.height * 0.12), // Spacer header
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Status & Tanggal Pengajuan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tanggal Pengajuan",
                                  style: TextStyle(
                                      color: labelColor, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: primaryBlue),
                                    const SizedBox(width: 5),
                                    Text(
                                      tglPengajuan,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: contentColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusApproval,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, thickness: 1),

                        // 2. Grid Informasi Utama
                        Text("Informasi Izin",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: jenisIcon,
                                label: "Jenis Izin",
                                value: jenisStatus,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.timer_outlined,
                                label: "Durasi",
                                value: "${widget.data['durasi']} Hari",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildInfoTileFull(
                          icon: Icons.date_range_rounded,
                          label: "Tanggal Izin",
                          value: tglIzin,
                        ),

                        const SizedBox(height: 25),

                        // 3. Keterangan Area
                        Text("Keterangan / Alasan",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: lightBlueBg, // Biru muda lembut
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.data['keterangan'] ?? '-',
                            style: const TextStyle(
                                height: 1.5, fontSize: 14, color: Colors.black87),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // 4. Lampiran Bukti
                        Text("Lampiran Bukti",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              if (imageUrl != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: InteractiveViewer(
                                    maxScale: 4.0,
                                    child: Image.network(
                                      imageUrl!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox(
                                            height: 100,
                                            child: Center(
                                                child: Text("Gagal memuat gambar")));
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _saveImage(context, imageUrl!),
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text("Unduh Lampiran"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryBlue,
                                      side: BorderSide(color: primaryBlue),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                )
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.image_not_supported_outlined,
                                          size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 10),
                                      Text("Tidak ada lampiran foto",
                                          style: TextStyle(
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget Helper untuk Tampilan Grid Kecil ---
  Widget _buildInfoCard(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryBlue),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(fontSize: 11, color: labelColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: contentColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- Widget Helper untuk Tampilan List Full Width ---
  Widget _buildInfoTileFull(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBlueBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: labelColor)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: contentColor)),
              ],
            ),
          )
        ],
      ),
    );
  }
}