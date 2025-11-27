import 'dart:async'; // Diperlukan untuk StreamSubscription
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mobileabsensi/notifikasi/notification_controller.dart';
import 'package:sp_util/sp_util.dart';

// Variabel global untuk menyimpan referensi ke listener
// Ini agar kita bisa membatalkannya saat user logout
List<StreamSubscription> firebaseSubscriptions = [];

/// Memulai listener (sebaiknya dipanggil saat user login)
Future<void> readData() async {
  // 1. Hentikan semua listener lama jika ada (mencegah duplikasi)
  stopFirebaseListeners();

  // 2. Dapatkan ID user yang sedang login
  final user = SpUtil.getString('id_user');
  final userId = int.tryParse(user ?? '');

  if (userId == null) {
    debugPrint('User ID tidak ditemukan, listener Firebase tidak dimulai.');
    return;
  }

  // 3. Tentukan 'key' yang akan kita filter di server
  // Kita hanya ingin data dengan status 0 dan id_atasan = userId
  final queryKey = "${userId}_0"; // Contoh: "123_0"
  final databaseReference = FirebaseDatabase.instance.ref();

  // --- 4. Kueri untuk 'izin' ---
  Query izinQuery = databaseReference
      .child('izin')
      .orderByChild('id_atasan_status') // Filter berdasarkan field gabungan
      .equalTo(queryKey); // Hanya ambil yang cocok (cth: "123_0")

  // .onChildAdded HANYA akan aktif untuk data baru yang cocok
  final izinSubscription = izinQuery.onChildAdded.listen(
    (event) => processNewEntry(event.snapshot, 'izin'), // Gunakan fungsi baru
    onError: (error) => debugPrint('Error pada listener izin: $error'),
  );
  firebaseSubscriptions.add(izinSubscription); // Simpan referensi listener

  // --- 5. Kueri untuk 'laporan' ---
  Query laporanQuery = databaseReference
      .child('laporan')
      .orderByChild('id_atasan_status') // Filter berdasarkan field gabungan
      .equalTo(queryKey); // Hanya ambil yang cocok (cth: "123_0")

  final laporanSubscription = laporanQuery.onChildAdded.listen(
    (event) => processNewEntry(event.snapshot, 'laporan'), // Gunakan fungsi baru
    onError: (error) => debugPrint('Error pada listener laporan: $error'),
  );
  firebaseSubscriptions.add(laporanSubscription); // Simpan referensi listener

  debugPrint('Firebase listeners dimulai untuk user $userId (QueryKey: $queryKey)');
}

/// Memproses SATU entri baru yang diterima dari listener onChildAdded
void processNewEntry(DataSnapshot snapshot, String notificationType) async {
  if (snapshot.value == null) return;

  final entryKey = snapshot.key.toString();
  
  // 1. Cek apakah notifikasi ini sudah pernah kita proses sebelumnya
  // Ini untuk mencegah notifikasi ganda saat aplikasi baru dimulai
  final processedKey = 'processed_${notificationType}_ids';
  final processedIds = Set<String>.from(SpUtil.getStringList(processedKey) ?? []);

  if (processedIds.contains(entryKey)) {
    // Ini normal, data ini sudah ada saat app start, tidak perlu notif lagi
    // debugPrint('Melewatkan entri $notificationType ($entryKey) yang sudah diproses');
    return;
  }

  // 2. Proses entri baru
  try {
    final documentData = snapshot.value as Map<dynamic, dynamic>;
    final idAtasan = documentData['id_atasan'];
    final idStatus = documentData['id_status'];
    final jenisIzin = documentData['jenis_izin'];

    final databaseReference = FirebaseDatabase.instance.ref();
    // Key baru setelah kita update statusnya menjadi 2
    final String newCompositeKey = '${idAtasan}_2'; 

    switch (notificationType) {
      case 'izin':
        await NotificationController.createNewNotificationIzin(
          1, idAtasan.toString(), jenisIzin, idStatus, notificationType,
          payloadId: entryKey,
        );
        // Update status di Firebase agar tidak diambil lagi oleh kueri "equalTo('..._0')"
        await databaseReference.child('izin').child(entryKey).update({
          'id_status': 2,
          'id_atasan_status': newCompositeKey // <-- PENTING!
        });
        break;
      case 'laporan':
        await NotificationController.createNewNotificationLaporan(
          2, idAtasan.toString(), null, idStatus, notificationType,
          payloadId: entryKey,
        );
        // Update status di Firebase
        await databaseReference.child('laporan').child(entryKey).update({
          'id_status': 2,
          'id_atasan_status': newCompositeKey // <-- PENTING!
        });
        break;
    }

    // 3. Tandai ID ini sebagai "sudah diproses" di lokal
    processedIds.add(entryKey);
    await SpUtil.putStringList(processedKey, processedIds.toList());
    debugPrint('Berhasil memproses notifikasi $notificationType dengan ID: $entryKey');

  } catch (e) {
    debugPrint('Error memproses notifikasi $notificationType ($entryKey): $e');
  }
}

/// Menghentikan semua listener Firebase (panggil ini saat user logout)
void stopFirebaseListeners() {
  for (var subscription in firebaseSubscriptions) {
    subscription.cancel();
  }
  firebaseSubscriptions.clear();
  debugPrint('Semua listener Firebase telah dihentikan.');
}