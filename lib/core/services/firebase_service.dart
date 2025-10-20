import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:sp_util/sp_util.dart';

/// Memulai listener untuk data 'izin' dan 'laporan' di Firebase
Future<void> readData() async {
  final databaseReference = FirebaseDatabase.instance.ref();
  databaseReference.child('izin').onValue.listen(
        (event) => processSnapshot(event.snapshot, 'izin'),
        onError: (error) => debugPrint('Terjadi kesalahan pada child izin: $error'),
      );
  databaseReference.child('laporan').onValue.listen(
        (event) => processSnapshot(event.snapshot, 'laporan'),
        onError: (error) => debugPrint('Terjadi kesalahan pada child laporan: $error'),
      );
}

/// Memproses snapshot yang diterima dari Firebase
void processSnapshot(DataSnapshot? snapshot, String notificationType) async {
  if (snapshot == null || snapshot.value == null) return;
  
  final data = snapshot.value as Map<dynamic, dynamic>?;
  if (data == null || data.isEmpty) {
    // debugPrint('Data $notificationType tidak ditemukan');
    return;
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final processedKey = 'processed_${notificationType}_ids';
  final processedIds = Set<String>.from(SpUtil.getStringList(processedKey) ?? []);
  
  // Filter entri yang baru dan valid (timestamp 5 menit terakhir, id_status = 0)
  final validEntries = data.entries.where((entry) {
    if (processedIds.contains(entry.key)) return false;
    final doc = entry.value as Map<dynamic, dynamic>?;
    final timestamp = doc?['timestamp'] as int?;
    final idStatus = doc?['id_status'];
    return timestamp != null && 
           timestamp > (now - 300000) && 
           timestamp <= now && 
           idStatus == 0;
  }).toList();

  if (validEntries.isEmpty) {
    // debugPrint('Tidak ada data $notificationType baru yang perlu diproses');
    return;
  }

  // Urutkan untuk mendapatkan yang terbaru
  validEntries.sort((a, b) {
    final aTimestamp = (a.value as Map<dynamic, dynamic>)['timestamp'] as int;
    final bTimestamp = (b.value as Map<dynamic, dynamic>)['timestamp'] as int;
    return bTimestamp.compareTo(aTimestamp);
  });

  final latestEntry = validEntries.first;
  final documentData = latestEntry.value as Map<dynamic, dynamic>;
  final entryKey = latestEntry.key.toString();
  final idAtasan = documentData['id_atasan'];
  final idStatus = documentData['id_status'];
  final jenisIzin = documentData['jenis_izin'];
  
  final user = SpUtil.getString('id_user');
  final userId = int.tryParse(user ?? '');
  final parsedIdAtasan = int.tryParse(idAtasan.toString());

  // Proses hanya jika ID atasan cocok dengan user yang login
  if (userId == parsedIdAtasan) {
    try {
      final databaseReference = FirebaseDatabase.instance.ref();
      switch (notificationType) {
        case 'izin':
          await NotificationController.createNewNotificationIzin(
            1, idAtasan.toString(), jenisIzin, idStatus, notificationType,
            payloadId: entryKey,
          );
          await databaseReference.child('izin').child(entryKey).update({'id_status': 2});
          break;
        case 'laporan':
          await NotificationController.createNewNotificationLaporan(
            2, idAtasan.toString(), null, idStatus, notificationType,
            payloadId: entryKey,
          );
          await databaseReference.child('laporan').child(entryKey).update({'id_status': 2});
          break;
      }
      
      // Tandai ID sebagai sudah diproses
      processedIds.add(entryKey);
      await SpUtil.putStringList(processedKey, processedIds.toList());
      // debugPrint('Berhasil memproses notifikasi $notificationType dengan ID: $entryKey');
    } catch (e) {
      // if (kDebugMode) print('Error sending $notificationType notification: $e');
    }
  } else {
    // debugPrint('ID atasan tidak cocok dengan user saat ini untuk $notificationType: $entryKey');
  }
}