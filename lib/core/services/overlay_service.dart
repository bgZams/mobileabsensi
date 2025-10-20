// lib/core/services/overlay_service.dart

import 'package:flutter/material.dart';
import 'package:mobileabsensi/presentation/widgets/draggable_screenshot_button.dart';

class OverlayService {
  static OverlayEntry? _overlayEntry;

  // Ubah parameter untuk menerima BuildContext
  static void showScreenshotButton({
    required BuildContext context,
    required GlobalKey screenshotKey,
    VoidCallback? onScreenshotTaken,
    Function(String?)? onScreenshotSaved,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => DraggableScreenshotButton(
        screenshotKey: screenshotKey,
        onScreenshotTaken: onScreenshotTaken,
        onScreenshotSaved: onScreenshotSaved,
      ),
    );

    // Gunakan context yang diteruskan dari parameter
    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);
  }

  static void hideScreenshotButton() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}