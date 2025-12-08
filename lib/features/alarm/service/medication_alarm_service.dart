// lib/core/services/medication_alarm_service.dart

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicationAlarmService {
  static final MedicationAlarmService _instance = MedicationAlarmService._();
  factory MedicationAlarmService() => _instance;
  MedicationAlarmService._();

  /// Initialize alarm service
  static Future<void> initialize() async {
    await Alarm.init();
    await requestPermissions();
  }

  /// Request necessary permissions
  static Future<void> requestPermissions() async {
    // Android 13+ requires notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// Schedule medication alarm
  Future<bool> scheduleMedicationAlarm({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? imageUrl,
  }) async {
    try {
      final alarmSettings = AlarmSettings(
        id: _generateAlarmId(medicationId, scheduledTime),
        dateTime: scheduledTime,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        volumeSettings: const VolumeSettings.fixed(volume: 0.8),
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: 'وقت الدواء ⏰',
          body: '$medicationName - $dosage',
          stopButton: 'إيقاف',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
      debugPrint('✅ Scheduled alarm for $medicationName at ${scheduledTime.hour}:${scheduledTime.minute}');
      return true;
    } catch (e) {
      debugPrint('❌ Error scheduling alarm: $e');
      return false;
    }
  }

  /// Schedule multiple alarms for a medication
  Future<void> scheduleMedicationAlarms({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required List<String> times, // ["09:00", "14:00", "21:00"]
    String? imageUrl,
  }) async {
    final now = DateTime.now();

    for (final timeString in times) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await scheduleMedicationAlarm(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        imageUrl: imageUrl,
      );
    }
  }

  /// Cancel specific alarm
  Future<void> cancelAlarm(String medicationId, DateTime scheduledTime) async {
    final alarmId = _generateAlarmId(medicationId, scheduledTime);
    await Alarm.stop(alarmId);
    debugPrint('✅ Cancelled alarm #$alarmId');
  }

  /// Cancel all alarms for a medication
  Future<void> cancelMedicationAlarms(
      String medicationId,
      List<String> times,
      ) async {
    final now = DateTime.now();

    for (final timeString in times) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      await cancelAlarm(medicationId, scheduledTime);
    }
  }

  /// Cancel all alarms
  Future<void> cancelAllAlarms() async {
    await Alarm.stopAll();
    debugPrint('✅ Cancelled all alarms');
  }

  /// Get active alarms
  Future<List<AlarmSettings>> getActiveAlarms() {
    return Alarm.getAlarms();
  }

  /// Check if alarm is ringing
  Stream<AlarmSettings> get alarmStream => Alarm.ringStream.stream;

  /// Generate unique alarm ID
  int _generateAlarmId(String medicationId, DateTime time) {
    // Create unique ID from medication ID and time
    final timeString = '${time.hour}${time.minute}'.padLeft(4, '0');
    final medIdHash = medicationId.hashCode.abs() % 1000;
    return int.parse('$medIdHash$timeString');
  }

  /// Reschedule alarm (for snooze functionality)
  Future<void> snoozeAlarm(AlarmSettings alarm, {int minutes = 5}) async {
    await Alarm.stop(alarm.id);

    final newSettings = alarm.copyWith(
      dateTime: DateTime.now().add(Duration(minutes: minutes)),
    );

    await Alarm.set(alarmSettings: newSettings);
    debugPrint('⏰ Snoozed alarm #${alarm.id} for $minutes minutes');
  }

  /// Reschedule recurring alarms (daily/weekly)
  Future<void> rescheduleRecurringAlarms() async {
    final activeAlarms = await getActiveAlarms();
    final now = DateTime.now();

    for (var alarm in activeAlarms) {
      // If alarm time has passed, schedule for next occurrence
      if (alarm.dateTime.isBefore(now)) {
        final newDateTime = alarm.dateTime.add(const Duration(days: 1));

        final newSettings = alarm.copyWith(dateTime: newDateTime);
        await Alarm.set(alarmSettings: newSettings);

        debugPrint('🔄 Rescheduled alarm #${alarm.id} to ${newDateTime.hour}:${newDateTime.minute}');
      }
    }
  }
}