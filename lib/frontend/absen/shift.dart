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
    final now = DateTime.now();
    final startDate = DateTime.parse(shift['tgl_awal']);
    final endDate = DateTime.parse(shift['tgl_akhir']);
    
    // Untuk jam, kita perlu membuat objek DateTime yang lengkap
    final startJam = DateFormat('HH:mm').parse(shift['jam_mulai']);
    final endJam = DateFormat('HH:mm').parse(shift['jam_selesai']);
    
    final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, startJam.hour, startJam.minute);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, endJam.hour, endJam.minute);

    if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
      return 'Aktif';
    } else if (now.isBefore(startDateTime)) {
      return 'Akan Datang';
    } else {
      return 'Selesai';
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