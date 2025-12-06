import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// خدمة الإشعارات المحلية (Universal)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Notification service already initialized');
      return;
    }

    try {
      // تهيئة المناطق الزمنية
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Cairo')); // غير حسب بلدك

      // إعدادات Android
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      // تهيئة الإشعارات
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // طلب الأذونات لـ Android 13+
      if (Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notifications: $e');
      rethrow;
    }
  }

  /// معالجة الضغط على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');

    // معالجة الـ Actions
    if (response.actionId == 'mark_done') {
      debugPrint('✅ User marked as done from notification');
      // TODO: Mark medication as taken
    } else if (response.actionId == 'snooze') {
      debugPrint('⏰ User snoozed notification');
      // TODO: Snooze for 10 minutes
    }
  }

  /// التحقق من إمكانية جدولة الإشعارات الدقيقة (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canSchedule = await android?.canScheduleExactNotifications() ?? false;
      debugPrint('📱 Can schedule exact alarms: $canSchedule');
      return canSchedule;
    }
    return true; // iOS دائماً يسمح
  }

  /// طلب إذن جدولة الإشعارات الدقيقة (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestExactAlarmsPermission() ?? false;
      debugPrint('📱 Exact alarm permission granted: $granted');
      return granted;
    }
    return true;
  }

  /// جدولة تذكير يومي (يتكرر كل يوم)
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // التحقق من الأذونات
      bool canSchedule = await canScheduleExactAlarms();
      if (!canSchedule) {
        bool granted = await requestExactAlarmPermission();
        if (!granted) {
          throw PlatformException(
            code: 'exact_alarm_not_allowed',
            message: 'تحتاج إلى إذن جدولة الإشعارات الدقيقة',
          );
        }
      }

      // إلغاء الإشعار القديم إذا كان موجود
      await cancelReminder(id);

      // حساب موعد الإشعار التالي
      final now = DateTime.now();
      DateTime scheduleDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // لو الوقت فات، جدول لبكرة
      if (scheduleDate.isBefore(now)) {
        scheduleDate = scheduleDate.add(const Duration(days: 1));
      }

      // تفاصيل الإشعار لـ Android
      const androidDetails = AndroidNotificationDetails(
        'medication_reminders', // Channel ID
        'تذكيرات الأدوية', // Channel name
        channelDescription: 'إشعارات لتذكيرك بمواعيد الأدوية',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction('mark_done', 'تم ✅'),
          AndroidNotificationAction('snooze', 'تأجيل 10 دقائق'),
        ],
      );

      // تفاصيل الإشعار لـ iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // جدولة الإشعار
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduleDate, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // يتكرر يومياً
        payload: '$id|$title|${time.hour}:${time.minute}',
      );

      // حفظ معلومات التذكير
      await _saveReminderInfo(id, time);

      debugPrint('✅ Scheduled reminder #$id for ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('❌ Error scheduling reminder #$id: $e');
      rethrow;
    }
  }

  /// عرض إشعار فوري (لمرة واحدة)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const android = AndroidNotificationDetails(
        'instant_notifications',
        'إشعارات فورية',
        channelDescription: 'إشعارات فورية للتأكيدات والتنبيهات',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(android: android, iOS: ios),
        payload: payload,
      );

      debugPrint('✅ Showed instant notification #$id');
    } catch (e) {
      debugPrint('❌ Error showing instant notification #$id: $e');
    }
  }

  /// حفظ معلومات التذكير في SharedPreferences
  Future<void> _saveReminderInfo(int id, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'reminder_$id',
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
      debugPrint('💾 Saved reminder info #$id');
    } catch (e) {
      debugPrint('⚠️ Failed to save reminder info: $e');
    }
  }

  /// إلغاء تذكير محدد
  Future<void> cancelReminder(int id) async {
    try {
      await _notifications.cancel(id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reminder_$id');

      debugPrint('✅ Cancelled reminder #$id');
    } catch (e) {
      debugPrint('❌ Error cancelling reminder #$id: $e');
    }
  }

  /// التحقق من وجود تذكير
  Future<bool> isReminderSet(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('reminder_$id');
  }

  /// الحصول على وقت التذكير
  Future<TimeOfDay?> getReminderTime(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('reminder_$id');

      if (str == null) return null;

      final parts = str.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint('⚠️ Error getting reminder time: $e');
      return null;
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('reminder_'));
      for (var key in keys) {
        await prefs.remove(key);
      }

      debugPrint('✅ Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// الحصول على الإشعارات المجدولة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// تأجيل إشعار لمدة 10 دقائق
  Future<void> snoozeNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final now = DateTime.now();
      final snoozeTime = now.add(const Duration(minutes: 10));

      await _notifications.zonedSchedule(
        id + 10000, // معرف مختلف للتأجيل
        title,
        body,
        tz.TZDateTime.from(snoozeTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'تذكيرات الأدوية',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('⏰ Snoozed notification #$id for 10 minutes');
    } catch (e) {
      debugPrint('❌ Error snoozing notification: $e');
    }
  }
}