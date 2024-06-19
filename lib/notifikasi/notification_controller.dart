import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sp_util/sp_util.dart';

import '../main.dart';

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************
///
class NotificationController {
  static ReceivedAction? initialAction;

  ///  *********************************************
  ///     INITIALIZATIONS
  ///  *********************************************
  ///
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        null,//'resource://assets/images/small_app.png',
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification tests as alerts',
              playSound: true,
              onlyAlertOnce: true,
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple)
        ],
        debug: true);

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static ReceivePort? receivePort;
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort('Notification action port in main isolate')
      ..listen(
          (silentData) => onActionReceivedImplementationMethod(silentData));

    // This initialization only happens on main isolate
    IsolateNameServer.registerPortWithName(
        receivePort!.sendPort, 'notification_action_port');
  }

  // Future<void> startListeningNotificationEvents() async {
  //   AwesomeNotifications()
  //       .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  // }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  void updateFirebase(keyNotif) async {
    final DatabaseReference izinRef = FirebaseDatabase.instance.ref().child(keyNotif);
    final idUser = SpUtil.getString('id_user');
    Query query = izinRef.orderByChild("id_atasan").equalTo(idUser);
    DatabaseEvent event = await query.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, data) {
        if (data["id_status"] == 1 && data["key_notif"] == keyNotif) {
          // Perbarui data jika id_status adalah 1
          izinRef.child(key).update({"id_status": 0});
        }
      });
    }
  }

  @pragma('vm:entry-point')
  static  Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload ?? {};
    final navigate = payload["navigate"];

    if (navigate == "izin") {
      String keyNotif = "izin";

      // updateFirebase(keyNotif);
      final DatabaseReference izinRef = FirebaseDatabase.instance.ref().child(keyNotif);
      final idUser = SpUtil.getString('id_user');
      Query query = izinRef.orderByChild("id_atasan").equalTo(idUser);
      DatabaseEvent event = await query.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, data) {
          if (data["id_status"] == 2 && data["key_notif"] == keyNotif) {
            // Perbarui data jika id_status adalah 1
            izinRef.child(key).update({"id_status": 1});
          }
        });
      }
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/konfirmasi-izin',
          (route) =>
              (route.settings.name != '/konfirmasi-izin') || route.isFirst,
          arguments: receivedAction);
    } else if (navigate == "laporan") {

      String keyNotif = "laporan";

      // updateFirebase(keyNotif);
      final DatabaseReference izinRef = FirebaseDatabase.instance.ref().child(keyNotif);
      final idUser = SpUtil.getString('id_user');
      Query query = izinRef.orderByChild("id_atasan").equalTo(idUser);
      DatabaseEvent event = await query.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, data) {
          if (data["id_status"] == 2 && data["key_notif"] == keyNotif) {
            // Perbarui data jika id_status adalah 1
            izinRef.child(key).update({"id_status": 1});
          }
        });
      }
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/konfirmasi-izin',
          (route) =>
              (route.settings.name != '/konfirmasi-izin') || route.isFirst,
          arguments: receivedAction);
    } else if (navigate == "apel") {
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/apel', (route) => (route.settings.name != '/apel') || route.isFirst,
          arguments: receivedAction);
    } else if (navigate == "senam") {
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/senam',
          (route) => (route.settings.name != '/senam') || route.isFirst,
          arguments: receivedAction);
    }
  }

  static Future<void> onActionReceivedImplementationMethod(
      ReceivedAction receivedAction) async {}

  ///  *********************************************
  ///     REQUESTING NOTIFICATION PERMISSIONS
  ///  *********************************************
  ///
  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = MyApp.navigatorKey.currentContext!;
    await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Get Notified!',
                style: Theme.of(context).textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/animated-bell.gif',
                        height: MediaQuery.of(context).size.height * 0.3,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                    'Allow Awesome Notifications to send you beautiful notifications!'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Deny',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Allow',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.deepPurple),
                  )),
            ],
          );
        });
    return userAuthorized &&
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  ///  *********************************************
  ///     BACKGROUND TASKS TEST
  ///  *********************************************
  // static Future<void> executeLongTaskInBackground() async {
  //   print("starting long task");
  //   await Future.delayed(const Duration(seconds: 4));
  //   final url = Uri.parse("http://google.com");
  //   final re = await http.get(url);
  //   print(re.body);
  //   print("long task done");
  // }

  ///  *********************************************
  ///     NOTIFICATION CREATION METHODS
  ///  *********************************************
  ///
  ///

  static Future<void> createNewNotificationIzin(
    int countIzin, String idAtasan, String jenisIzin, int idStatus, String keyNotif) async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) isAllowed = await displayNotificationRationale();
  if (!isAllowed) return;

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: -1, // -1 is replaced by a random number
      channelKey: 'alerts',
      // title: SpUtil.getString('nama_lengkap'),
      title: 'Izin',
      body: "Terdapat $countIzin pengajuan $keyNotif yang harus di tindaklanjuti!",
      // bigPicture: 'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
      largeIcon: 'Asset://assets/images/logoapp.png',
      notificationLayout: NotificationLayout.BigPicture,
      payload: {
        'navigate': 'izin',
      }
    ),
    actionButtons: [
      NotificationActionButton(key: 'REDIRECT', label: 'Lihat'),
      NotificationActionButton(
        key: 'CLOSE',
        label: 'Tutup',
        actionType: ActionType.SilentAction,
      ),
    ],
  );
}


  static Future<void> createNewNotificationLaporan(
      int jlhCountLaporan, idAtasan, jenisIzin, idStatus, keyNotif) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // -1 is replaced by a random number
            channelKey: 'alerts',
            // title: SpUtil.getString('nama_lengkap'),
            title: 'Laporan Harian',
            body:
                "Terdapat $jlhCountLaporan pengajuan $keyNotif yang harus di tindaklanjuti!",
            // bigPicture:
            //     'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
            largeIcon: 'asset://assets/images/logo.png',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {
              'navigate': 'laporan',
            }),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Lihat'),
          NotificationActionButton(
              key: 'CLOSE',
              label: 'Tutup',
              actionType: ActionType.SilentAction),
        ]);
  }

  static Future<void> createNewNotificationSenam(
      int jlhCountSenam, idAtasan, jenisIzin, idStatus, keyNotif) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // -1 is replaced by a random number
            channelKey: 'alerts',
            title: SpUtil.getString('nama_lengkap'),
            body:
                "Terdapat $jlhCountSenam pengajuan $keyNotif yang harus di tindaklanjuti!",
            // bigPicture:
            //     'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
            largeIcon: 'asset://assets/images/logo.png',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {
              'navigate': 'senam',
            }),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Lihat'),
          NotificationActionButton(
              key: 'CLOSE',
              label: 'Tutup',
              actionType: ActionType.SilentAction),
        ]);
  }

  static Future<void> createNewNotificationApel(
      int jlhCountApel, idAtasan, jenisIzin, idStatus, keyNotif) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // -1 is replaced by a random number
            channelKey: 'alerts',
            title: SpUtil.getString('nama_lengkap'),
            body:
                "Terdapat $jlhCountApel pengajuan $keyNotif yang harus di tindaklanjuti!",
            // bigPicture:
            //     'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
            largeIcon: 'asset://assets/images/logo.png',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {
              'navigate': 'apel',
            }),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Lihat'),
          NotificationActionButton(
              key: 'CLOSE',
              label: 'Tutup',
              actionType: ActionType.SilentAction),
        ]);
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
