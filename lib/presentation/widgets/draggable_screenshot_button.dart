import 'package:flutter/material.dart';
import 'package:mobileabsensi/screenshoot.dart'; // Import ScreenshotButton Anda

class DraggableScreenshotButton extends StatefulWidget {
  final GlobalKey screenshotKey;
  final VoidCallback? onScreenshotTaken;
  final Function(String?)? onScreenshotSaved;

  const DraggableScreenshotButton({
    super.key,
    required this.screenshotKey,
    this.onScreenshotTaken,
    this.onScreenshotSaved,
  });

  @override
  State<DraggableScreenshotButton> createState() => _DraggableScreenshotButtonState();
}

class _DraggableScreenshotButtonState extends State<DraggableScreenshotButton> {
  Offset _cameraPosition = Offset.zero;
  bool _isDragging = false;
  bool _isInitialized = false; // Tambahkan flag untuk inisialisasi

  // PERBAIKAN 1: Gunakan didChangeDependencies untuk inisialisasi posisi
  // Method ini dipanggil setelah initState dan saat InheritedWidget (seperti MediaQuery) berubah.
  // Ini adalah tempat yang lebih andal untuk mendapatkan ukuran layar sebelum build pertama kali.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Ambil ukuran layar dari MediaQuery
      final screenSize = MediaQuery.of(context).size;
      // Atur posisi awal langsung, tanpa setState, karena ini terjadi sebelum build pertama.
      _cameraPosition = Offset(
        screenSize.width - 80, // 80 = 60 (lebar tombol) + 20 (margin)
        screenSize.height * 0.5 - 30, // Posisi di tengah vertikal
      );
    }
  }

  // PERBAIKAN 2: Perbaiki logika pembaruan posisi saat digeser
  void _updatePosition(Offset delta) {
    // Gunakan MediaQuery.of(context) untuk mendapatkan ukuran layar yang BENAR.
    // Jangan gunakan context.findRenderObject() karena itu hanya mengembalikan ukuran widget ini.
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = 60.0; // Asumsikan ukuran tombol 60x60

    setState(() {
      // Tambahkan delta (perubahan posisi) ke posisi saat ini
      Offset newPosition = _cameraPosition + delta;

      // Batasi posisi baru agar tombol tidak keluar dari layar
      _cameraPosition = Offset(
        newPosition.dx.clamp(0.0, screenSize.width - buttonSize),
        newPosition.dy.clamp(0.0, screenSize.height - buttonSize),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _cameraPosition.dx,
      top: _cameraPosition.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) => _updatePosition(details.delta),
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: Opacity(
          opacity: _isDragging ? 0.8 : 1.0,
          child: ScreenshotButton(
            screenshotKey: widget.screenshotKey,
            onScreenshotTaken: widget.onScreenshotTaken,
            onScreenshotSaved: widget.onScreenshotSaved,
          ),
        ),
      ),
    );
  }
}