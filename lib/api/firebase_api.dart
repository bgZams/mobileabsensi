// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:mobileabsensi/main.dart';

// class FirebaseApi {
//   final _firebaseMessanging = FirebaseMessaging.instance;
//   Future<void> initNotifications() async {
//     await _firebaseMessanging.requestPermission();

//     final fCMToken = await _firebaseMessanging.getToken();

//     if (kDebugMode) {
//       print('token: $fCMToken');
//     }
//     initPushNotifications();
//   }

//   void handleMessage(RemoteMessage? message) {
//     if (message == null) return;
//     navigatorKey.currentState?.pushNamed('notifikasi-laporan-harian', arguments: message);
//   }

//   Future initPushNotifications() async {
//     FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
//     FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
//   }
// }
