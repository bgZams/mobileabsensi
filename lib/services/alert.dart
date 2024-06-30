import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class Alert {
  static void alertwarning(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      text: message,
    );
  }
  static void alertsuccess(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: message,
    );
  }
  static void alertinfo(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      text: message,
    );
  }
  static void alerterror(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      text: message,
    );
  }
}
