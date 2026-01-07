import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotButton extends StatefulWidget {
  final GlobalKey? screenshotKey;
  final VoidCallback? onScreenshotTaken;
  final Function(String?)? onScreenshotSaved; // Callback dengan path file
  
  const ScreenshotButton({
    Key? key,
    this.screenshotKey,
    this.onScreenshotTaken,
    this.onScreenshotSaved,
  }) : super(key: key);

  @override
  State<ScreenshotButton> createState() => _ScreenshotButtonState();
}

class _ScreenshotButtonState extends State<ScreenshotButton>
  with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method untuk meminta izin penyimpanan
  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }
Future<String?> _saveScreenshotToGallery(Uint8List pngBytes) async {
  try {
    // Pastikan channel ini sama dengan yang di MainActivity.kt
    const platform = MethodChannel('com.pasbar.mobileabsensi/gallery_saver'); 
    
    final result = await platform.invokeMethod('saveImage', {
      'bytes': pngBytes,
      'name': 'screenshot_${DateTime.now().millisecondsSinceEpoch}',
    });
    
    if (result != null && result is String) {
      return result;
    }
    
    throw Exception('Penyimpanan gagal, path tidak valid.');
  } catch (e) {
    print('Error saving to gallery via method channel: $e');
    return null;
  }
}

// Untuk iOS
Future<String?> _saveToIOSGallery(Uint8List pngBytes) async {
  try {
    // Untuk iOS, simpan ke temporary directory dulu
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);

    // Untuk iOS, kita perlu menggunakan method channel untuk save ke photo library
    // Tapi untuk simplicity, kita return path temporary
    return file.path;
  } catch (e) {
    print('Error saving to iOS gallery: $e');
    return null;
  }
}

  Future<void> _captureScreenshot() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      // Animasi tombol ditekan
      await _animationController.forward();
      await _animationController.reverse();

      // Ambil screenshot
      RenderRepaintBoundary? boundary;
      
      if (widget.screenshotKey != null) {
        boundary = widget.screenshotKey!.currentContext?.findRenderObject() 
            as RenderRepaintBoundary?;
      } else {
        RenderObject? renderObject = context.findRenderObject();
        while (renderObject != null && renderObject is! RenderRepaintBoundary) {
          renderObject = renderObject.parent;
        }
        boundary = renderObject as RenderRepaintBoundary?;
      }

      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();
          
          // Simpan screenshot ke galeri
          String? savedPath = await _saveScreenshotToGallery(pngBytes);
          
          // Tampilkan pesan sukses
          // Tampilkan pesan sukses
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(savedPath != null 
                      ? 'Gambar disimpan di galeri!' 
                      : 'Gambar berhasil diambil!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }

          // Callback ketika screenshot berhasil
          widget.onScreenshotTaken?.call();
          widget.onScreenshotSaved?.call(savedPath);
        }
      } else {
        throw Exception('Tidak dapat menemukan RenderRepaintBoundary');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // Hapus method _showScreenshotDialog karena tidak bisa langsung akses galeri

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade700,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _isCapturing ? null : _captureScreenshot,
                child: Center(
                  child: _isCapturing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.screenshot,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}