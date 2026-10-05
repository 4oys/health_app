import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/models.dart';

class HealthSyncService {
  final Health _health = Health();
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_ASLEEP,
  ];

  Future<bool> requestAccess() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (Platform.isAndroid) {
      final activityPermission = await Permission.activityRecognition.request();
      if (!activityPermission.isGranted) return false;
    }
    await _health.configure();
    return _health.requestAuthorization(_types,
        permissions: List.filled(_types.length, HealthDataAccess.READ));
  }

  Future<ActivityRecord> read(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final until = end.isAfter(DateTime.now()) ? DateTime.now() : end;
    await _health.configure();
    final steps = await _health.getTotalStepsInInterval(start, until) ?? 0;
    final values = _health.removeDuplicates(
        await _health.getHealthDataFromTypes(
            types: _types.sublist(1), startTime: start, endTime: until));
    int minutes(HealthDataType type) =>
        values.where((point) => point.type == type).fold(
            0,
            (sum, point) =>
                sum + point.dateTo.difference(point.dateFrom).inMinutes);
    final heart = values
        .where((point) =>
            point.type == HealthDataType.HEART_RATE &&
            point.value is NumericHealthValue)
        .toList()
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final heartRate = heart.isEmpty
        ? 0
        : (heart.last.value as NumericHealthValue).numericValue.round();
    final deep = minutes(HealthDataType.SLEEP_DEEP);
    final light = minutes(HealthDataType.SLEEP_LIGHT);
    final rem = minutes(HealthDataType.SLEEP_REM);
    final unspecified = minutes(HealthDataType.SLEEP_ASLEEP);
    return ActivityRecord(
        date: date,
        steps: steps,
        heartRate: heartRate,
        sleepMinutes: deep + light + rem + unspecified,
        deepMinutes: deep,
        lightMinutes: light,
        remMinutes: rem);
  }
}
