import 'package:flutter/material.dart';

class ScreenshotProvider extends ChangeNotifier {
  final GlobalKey _screenshotKey = GlobalKey();
  Offset _cameraPosition = Offset.zero;
  bool _isDragging = false;
  bool _isVisible = true;

  GlobalKey get screenshotKey => _screenshotKey;
  Offset get cameraPosition => _cameraPosition;
  bool get isDragging => _isDragging;
  bool get isVisible => _isVisible;

   

  void updateCameraPosition(Offset newPosition) {
    _cameraPosition = newPosition;
    notifyListeners();
  }

  void updateDragging(bool dragging) {
    _isDragging = dragging;
    notifyListeners();
  }

  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
 
}