import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sp_util/sp_util.dart';

void checkAndUpdatePreferences() {
  String idType = SpUtil.getString('id_type') ?? '';

  if (idType == "0") {
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);

    final savedDate = SpUtil.getString('saved_date');

    if (savedDate != todayString) {
      debugPrint("📅 Hari baru terdeteksi untuk Type 0. Melakukan Reset Data...");

      _fullResetAttendanceData();

      SpUtil.putString('saved_date', todayString);
    }
  } else if (idType == "1") {
    _checkAndUpdateShiftReset();
  }
}

void _fullResetAttendanceData() {
  debugPrint("🧹 Menghapus data absensi harian...");
  SpUtil.putBool('is_codeMasuk', false);
  SpUtil.putBool('is_codePulang', false);
  SpUtil.putBool('is_PulangCepat', false);
  SpUtil.putBool('_isMasuk', false);
  SpUtil.putBool('_isPulang', false);
  SpUtil.putString('statusPC', 'pending');
  SpUtil.putBool('is_IDLK', false);
  SpUtil.putString('status_idlk', 'pending');
  SpUtil.remove('masuk');
  SpUtil.remove('pulang');
}

void _checkAndUpdateShiftReset() {
  final shiftDataString = SpUtil.getString('shift_data');
  if (shiftDataString == null || shiftDataString.isEmpty) return;

  try {
    final dynamic decoded = json.decode(shiftDataString);
    List shiftList = [];
    if (decoded is List) {
      shiftList = decoded;
    } else if (decoded is Map) {
      shiftList = [
        decoded
      ];
    }

    final now = DateTime.now();
    final currentShiftId = SpUtil.getString('current_shift_id');

    if (currentShiftId != null) {
      Map? currentShift = _findShiftById(shiftList, currentShiftId);

      if (currentShift != null) {
        final resetTime = _calculateResetTime(currentShift);
        if (now.isAfter(resetTime)) {
          _fullResetAttendanceData();
          SpUtil.remove('current_shift_id');
          SpUtil.remove('saved_date');
          return;
        } else {
          debugPrint('⏳ Belum waktunya reset shift (Reset time: $resetTime)');
          return;
        }
      }
    }

    Map? activeShift = _findActiveShift(shiftList, now);

    if (activeShift != null) {
      final newShiftId = activeShift['id'].toString();

      if (currentShiftId != null && currentShiftId != newShiftId) {
        _fullResetAttendanceData();
      }

      SpUtil.putString('current_shift_id', newShiftId);
      SpUtil.putString('saved_date', activeShift['tgl_awal']);
    } else {
      debugPrint('❌ Tidak ada shift aktif saat ini');
    }
  } catch (e) {
    debugPrint('❌ Error in _checkAndUpdateShiftReset: $e');
  }
}

DateTime _calculateResetTime(Map shift) {
  final tglAkhir = DateTime.parse(shift['tgl_akhir']);
  final jamSelesaiParts = (shift['jam_selesai'] as String).split(':');
  final shiftEndTime = DateTime(
    tglAkhir.year,
    tglAkhir.month,
    tglAkhir.day,
    int.parse(jamSelesaiParts[0]),
    int.parse(jamSelesaiParts[1]),
  );
  return shiftEndTime.add(const Duration(hours: 8));
}

Map? _findActiveShift(List shiftList, DateTime now) {
  for (final shift in shiftList) {
    final shiftStart = _parseDateTime(shift['tgl_awal'], shift['jam_mulai']);
    final shiftEnd = _parseDateTime(shift['tgl_akhir'], shift['jam_selesai']);

    final startTolerance = shiftStart.subtract(const Duration(hours: 5));

    if (now.isAfter(startTolerance) && now.isBefore(shiftEnd.add(const Duration(minutes: 1)))) {
      return shift;
    }
  }
  return null;
}

Map? _findShiftById(List shiftList, String shiftId) {
  try {
    return shiftList.firstWhere((shift) => shift['id'].toString() == shiftId);
  } catch (e) {
    return null;
  }
}

DateTime _parseDateTime(String dateString, String timeString) {
  final date = DateTime.parse(dateString);
  final timeParts = timeString.split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
  );
}
