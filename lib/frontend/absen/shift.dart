import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_util/sp_util.dart';

class Shift extends StatefulWidget {
  const Shift({super.key});

  @override
  State<Shift> createState() => _ShiftState();
}

class _ShiftState extends State<Shift> {
  List<Map<String, dynamic>> _shifts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  // Fungsi untuk mengambil dan mem-parsing data shift dari SpUtil
  Future<void> _loadShiftData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final shiftDataString = SpUtil.getString('shift_data');
      print(shiftDataString);
      if (shiftDataString != null && shiftDataString.isNotEmpty) {
        final dynamic decoded = json.decode(shiftDataString);
        List<dynamic> dataList = [];
        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map) {
          dataList = [decoded];
        }
        
        setState(() {
          _shifts = List<Map<String, dynamic>>.from(dataList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error parsing shift data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Fungsi untuk menentukan status shift
 String _getShiftStatus(Map<String, dynamic> shift) {
  // 1. Ambil waktu sekarang
  final DateTime nowRaw = DateTime.now();
  
  // 2. NORMALISASI: Buang elemen jam, menit, detik. Jadikan 00:00:00 semua.
  final DateTime today = DateTime(nowRaw.year, nowRaw.month, nowRaw.day);
  final DateTime startDate = DateTime.parse(shift['tgl_awal']); // Parse defaultnya sdh 00:00
  final DateTime endDate = DateTime.parse(shift['tgl_akhir']);  // Parse defaultnya sdh 00:00

  // 3. Logika Perbandingan (Hanya Tanggal)
  if (today.isBefore(startDate)) {
    // Jika hari ini < tanggal awal
    return 'Akan Datang';
  } else if (today.isAfter(endDate)) {
    // Jika hari ini > tanggal akhir
    return 'Selesai';
  } else {
    // Jika tidak sebelum dan tidak sesudah, berarti sedang berjalan
    // (Termasuk jika hari ini == startDate atau hari ini == endDate)
    return 'Aktif';
  }
}

  // Fungsi untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return Colors.green.shade600;
      case 'Akan Datang':
        return Colors.orange.shade600;
      case 'Selesai':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Shift', style: TextStyle(color: Colors.white),),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Gagal memuat data.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadShiftData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Belum ada jadwal shift.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _shifts.length,
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        final status = _getShiftStatus(shift);
        final statusColor = _getStatusColor(status);

        // Memformat tanggal
        final tglAwal = DateTime.parse(shift['tgl_awal']);
        final tglAkhir = DateTime.parse(shift['tgl_akhir']);
        final formattedTglAwal = DateFormat('dd MMM yyyy').format(tglAwal);
        final formattedTglAkhir = DateFormat('dd MMM yyyy').format(tglAkhir);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Nomor Shift dan Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shift Ke: ${shift['shift_ke']}',
                    ),
                    Chip(
                      label: Text(
                        status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Detail Tanggal
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Tanggal:',
                  value: '$formattedTglAwal - $formattedTglAkhir',
                ),
                const SizedBox(height: 12),

                // Detail Jam
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Jam:',
                  value: '${shift['jam_mulai']} - ${shift['jam_selesai']} WIB',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget helper untuk menampilkan baris detail (ikon + teks)
  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}