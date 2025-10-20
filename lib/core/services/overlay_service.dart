// lib/core/services/overlay_service.dart

import 'package:flutter/material.dart';
import 'package:mobileabsensi/presentation/widgets/draggable_screenshot_button.dart';

class OverlayService {
  static OverlayEntry? _overlayEntry;
  static bool _isInitialized = false;

  // Method untuk menampilkan button screenshot
  static void showScreenshotButton({
    required BuildContext context,
    required GlobalKey screenshotKey,
    VoidCallback? onScreenshotTaken,
    Function(String?)? onScreenshotSaved,
  }) {
    // Cek apakah sudah diinisialisasi sebelumnya
    if (_isInitialized) {
      debugPrint('⚠️ OverlayService: Screenshot button already initialized');
      return;
    }

    // Hapus overlay lama jika ada
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } catch (e) {
        debugPrint('⚠️ Error removing old overlay: $e');
      }
    }

    try {
      _overlayEntry = OverlayEntry(
        builder: (context) => DraggableScreenshotButton(
          screenshotKey: screenshotKey,
          onScreenshotTaken: onScreenshotTaken,
          onScreenshotSaved: onScreenshotSaved,
        ),
      );

      final overlay = Overlay.of(context);
      overlay.insert(_overlayEntry!);
      _isInitialized = true;
      debugPrint('✅ OverlayService: Screenshot button initialized successfully');
    } catch (e) {
      debugPrint('❌ Error showing screenshot button: $e');
      _overlayEntry = null;
      _isInitialized = false;
    }
  }

  // Method untuk menyembunyikan button screenshot
  static void hideScreenshotButton() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isInitialized = false;
        debugPrint('✅ OverlayService: Screenshot button removed');
      } catch (e) {
        debugPrint('⚠️ Error hiding screenshot button: $e');
      }
    }
  }

  // Getter untuk mengecek status
  static bool get isInitialized => _isInitialized;

  // Method untuk reset (gunakan saat hot reload atau debugging)
  static void reset() {
    hideScreenshotButton();
    _isInitialized = false;
  }
}