import 'package:flutter/material.dart';
import 'package:mobileabsensi/screenshoot.dart';

class GlobalScreenshot extends StatefulWidget {
  final Widget child;
  final GlobalKey? screenshotKey;

  const GlobalScreenshot({
    super.key,
    required this.child,
    this.screenshotKey,
  });

  @override
  State<GlobalScreenshot> createState() => _GlobalScreenshotState();
}

class _GlobalScreenshotState extends State<GlobalScreenshot> {
  final GlobalKey _screenshotKey = GlobalKey();
  Offset _cameraPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi posisi tombol setelah widget pertama kali dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cameraPosition == Offset.zero) {
        setState(() {
          _cameraPosition = Offset(
            MediaQuery.of(context).size.width - 80,
            MediaQuery.of(context).size.height * 0.5 - 30,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Konten utama aplikasi
        RepaintBoundary(
          key: widget.screenshotKey ?? _screenshotKey,
          child: widget.child,
        ),
        
        // Tombol screenshot yang bisa digeser
        Positioned(
          left: _cameraPosition.dx,
          top: _cameraPosition.dy,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _cameraPosition += details.delta;
                
                // Batasi agar tidak keluar dari layar
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                
                if (_cameraPosition.dx < 0) _cameraPosition = Offset(0, _cameraPosition.dy);
                if (_cameraPosition.dx > screenWidth - 60) {
                  _cameraPosition = Offset(screenWidth - 60, _cameraPosition.dy);
                }
                if (_cameraPosition.dy < 0) _cameraPosition = Offset(_cameraPosition.dx, 0);
                if (_cameraPosition.dy > screenHeight - 60) {
                  _cameraPosition = Offset(_cameraPosition.dx, screenHeight - 60);
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Opacity(
              opacity: _isDragging ? 0.8 : 1.0,
              child: ScreenshotButton(
                screenshotKey: widget.screenshotKey ?? _screenshotKey,
                onScreenshotTaken: () {
                  // print('Screenshot berhasil diambil!');
                },
                onScreenshotSaved: (String? path) {
                  if (path != null) {
                    // print('Screenshot disimpan di: $path');
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}