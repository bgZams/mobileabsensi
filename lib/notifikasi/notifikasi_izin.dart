// import 'package:firebase_database/firebase_database.dart';
// import 'notification_controller.dart';

// class NotifikasiIzin {
//   final DatabaseReference databaseReference =
//       FirebaseDatabase.instance.reference();

//   void setupDataListener() {
//     databaseReference.child('izin').onChildChanged.listen((event) {
//       DataSnapshot snapshot = event.snapshot;
//       if (snapshot.value != null) {
//         final Map<String, dynamic>? data =
//             snapshot.value as Map<String, dynamic>?;
//         if (data != null) {
//           final idAtasan = data['id_atasan'];
//           final idUser = data['id_user'];
//           final idStatus = data['id_status'];

//           if (idAtasan == idUser && idStatus == 1) {
//             NotificationController.createNewNotification();
//           }
//         }
//       }
//     });
//   }
// }
