import 'package:flutter/material.dart';
import 'package:mobileabsensi/core/services/secure_debugging.dart';

class ScreenWrapper extends StatefulWidget {
  final Widget child;

  const ScreenWrapper({super.key, required this.child});

  @override
  State<ScreenWrapper> createState() => _ScreenWrapperState();
}

class _ScreenWrapperState extends State<ScreenWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _periksaKeamanan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _periksaKeamanan();
    }
  }

  void _periksaKeamanan() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SecurityService.checkDebug(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
