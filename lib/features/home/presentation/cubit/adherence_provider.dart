import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/core/db/database_helper.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/service/notification_helper.dart';
import 'package:uuid/uuid.dart';

enum AdherenceStatus { idle, loading, success, error }

class AdherenceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _localDb = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  AdherenceStatus _status = AdherenceStatus.idle;
  Map<String, Map<String, bool>> _adherenceCache = {};
  String? _errorMessage;

  // Getters
  AdherenceStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdherenceStatus.loading;

  /// تحميل الالتزام لليوم
  Future<void> loadTodaysAdherence(String userId) async {
    if (_status == AdherenceStatus.loading) return;

    try {
      _status = AdherenceStatus.loading;
      notifyListeners();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: userId)
          .where('scheduledTime',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('scheduledTime',
          isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      _adherenceCache.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final medicationId = data['medicationId'] as String;
        final scheduledTime = data['scheduledTime'] as String;
        final status = data['status'] as String;

        final time = _extractTimeFromIso(scheduledTime);
        final key = _generateKey(medicationId, time);

        _adherenceCache[key] = {
          'taken': status == 'taken',
          'missed': status == 'missed',
          'skipped': status == 'skipped',
        };
      }

      _status = AdherenceStatus.success;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading adherence: $e');
      _status = AdherenceStatus.error;
      _errorMessage = 'فشل تحميل سجل الالتزام';
      notifyListeners();
    }
  }

  /// تسجيل الجرعة (تم التناول)
  Future<bool> markMedicationAsTaken({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String time,
  }) async {
    try {
      final key = _generateKey(medicationId, time);

      // تحقق من التكرار
      if (_adherenceCache[key]?['taken'] == true) {
        _errorMessage = 'تم تسجيل الدواء مسبقًا';
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final logId = _uuid.v4();

      final timeParts = time.split(':');
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final adherenceLog = {
        'id': logId,
        'userId': userId,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'scheduledTime': scheduledTime.toIso8601String(),
        'takenTime': now.toIso8601String(),
        'status': 'taken',
        'notes': null,
      };

      // حفظ في Firestore
      await _firestore.collection('adherence_logs').doc(logId).set(adherenceLog);

      // حفظ محليًا
      try {
        await _localDb.insertAdherenceLog(adherenceLog);
      } catch (e) {
        debugPrint('Local DB save failed: $e');
      }

      // تحديث الكاش
      _adherenceCache[key] = {'taken': true, 'missed': false};

      // إشعار تأكيد
      await _notificationService.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '✅ تم تسجيل الجرعة',
        body: 'تم تسجيل $medicationName - $time بنجاح',
      );

      _status = AdherenceStatus.success;
      notifyListeners();

      debugPrint('✅ Medication marked as taken: $medicationName at $time');
      return true;
    } catch (e) {
      debugPrint('Error marking as taken: $e');
      _errorMessage = 'فشل تسجيل الدواء';
      notifyListeners();
      return false;
    }
  }

  /// حساب نسبة الالتزام (محسّن)
  Future<double> calculateAdherenceRate(String userId, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: userId)
          .where('scheduledTime',
          isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('scheduledTime',
          isLessThanOrEqualTo: now.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No adherence logs found for user $userId');
        return 0.0;
      }

      final taken = snapshot.docs.where((doc) {
        try {
          return doc.data()['status'] == 'taken';
        } catch (e) {
          debugPrint('Error reading doc status: $e');
          return false;
        }
      }).length;

      final total = snapshot.docs.length;

      final rate = total > 0 ? (taken / total) * 100 : 0.0;

      debugPrint('📊 Adherence Rate: ${rate.toStringAsFixed(1)}% ($taken/$total)');

      return rate;
    } catch (e) {
      debugPrint('❌ Error calculating rate: $e');
      return 0.0;
    }
  }

  /// حساب الـ streak (أيام متتالية من الالتزام)
  Future<int> calculateStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final snapshot = await _firestore
            .collection('adherence_logs')
            .where('userId', isEqualTo: userId)
            .where('scheduledTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('scheduledTime',
            isLessThanOrEqualTo: endOfDay.toIso8601String())
            .get();

        if (snapshot.docs.isEmpty) {
          // مفيش أدوية في اليوم ده
          continue;
        }

        final taken = snapshot.docs.where((doc) => doc['status'] == 'taken').length;
        final total = snapshot.docs.length;
        final dayRate = (taken / total) * 100;

        // الالتزام أكثر من 80% = يوم ناجح
        if (dayRate >= 80) {
          streak++;
        } else {
          // فشل يوم = نوقف الـ streak
          break;
        }
      }

      debugPrint('🔥 Current streak: $streak days');
      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating streak: $e');
      return 0;
    }
  }

  /// تحديد ما إذا كان الدواء مأخوذًا
  bool isMedicationTaken(String medicationId, String time) {
    final key = _generateKey(medicationId, time);
    return _adherenceCache[key]?['taken'] ?? false;
  }

  /// تحديد ما إذا فات الوقت
  bool hasMedicationTimePassed(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final medTime = DateTime(now.year, now.month, now.day, hour, minute);
    final windowEnd = medTime.add(const Duration(hours: 2));
    return now.isAfter(windowEnd);
  }

  /// تحديد ما إذا كان الوقت الآن
  bool isMedicationDueNow(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final medTime = DateTime(now.year, now.month, now.day, hour, minute);
    final start = medTime.subtract(const Duration(minutes: 30));
    final end = medTime.add(const Duration(hours: 2));
    return now.isAfter(start) && now.isBefore(end);
  }

  /// تحديد الدواء المُفوّت تلقائيًا
  Future<void> autoMarkMissedMedications(
      String userId,
      List<MedicationModel> medications,
      ) async {
    try {
      final now = DateTime.now();

      for (var med in medications) {
        for (var time in med.times) {
          final key = _generateKey(med.id, time);

          if (_adherenceCache[key]?['taken'] == true ||
              _adherenceCache[key]?['missed'] == true) {
            continue;
          }

          if (hasMedicationTimePassed(time)) {
            final parts = time.split(':');
            final scheduledTime = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );

            if (scheduledTime.day == now.day) {
              final logId = _uuid.v4();
              final log = {
                'id': logId,
                'userId': userId,
                'medicationId': med.id,
                'medicationName': med.name,
                'scheduledTime': scheduledTime.toIso8601String(),
                'takenTime': null,
                'status': 'missed',
                'notes': 'Auto-marked as missed',
              };

              await _firestore.collection('adherence_logs').doc(logId).set(log);
              _adherenceCache[key] = {'taken': false, 'missed': true};

              debugPrint('❌ Auto-marked ${med.name} at $time as missed');
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Auto-mark error: $e');
    }
  }

  /// تنظيف الأخطاء
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// مساعدات
  String _generateKey(String medicationId, String time) =>
      '${medicationId}_$time';

  String _extractTimeFromIso(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}