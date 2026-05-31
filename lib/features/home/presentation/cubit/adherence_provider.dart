import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/core/db/database_helper.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/features/alarm/service/medication_alarm_service.dart';
import 'package:uuid/uuid.dart';

enum AdherenceStatus { idle, loading, success, error }

class AdherenceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _localDb = DatabaseHelper();
  final MedicationAlarmService _alarmService = MedicationAlarmService();
  final Uuid _uuid = const Uuid();

  AdherenceStatus _status = AdherenceStatus.idle;
  Map<String, Map<String, bool>> _adherenceCache = {};
  String? _errorMessage;

  // Getters
  AdherenceStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdherenceStatus.loading;


  bool _isLoadingDose = false;
  bool get isLoadingDose => _isLoadingDose;

  /// تسجيل جرعة (سواء تم أخذها أو تفويتها)
  Future<void> logDose({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String status, // 'taken' or 'missed'
    required DateTime scheduledTime,
    DateTime? actualTime,
  }) async {
    try {
      _isLoadingDose = true;
      notifyListeners();

      // إنشاء سجل الجرعة
      final logData = {
        'userId': userId,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'status': status,
        'scheduledTime': scheduledTime.toIso8601String(),
        'actualTime': actualTime?.toIso8601String(),
        'loggedAt': DateTime.now().toIso8601String(),
      };

      // حفظ في Firestore
      // بنعمل Collection اسمه adherence_logs ونحفظ جواه
      await _firestore.collection('adherence_logs').add(logData);

      debugPrint('✅ Dose logged successfully: $status for $medicationName');
    } catch (e) {
      debugPrint('❌ Error logging dose: $e');
    } finally {
      _isLoadingDose = false;
      notifyListeners();
    }
  }

  /// مساعدة لجلب أدوية المستخدم
  Future<List<MedicationModel>> _getUserMedications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('medications')
          .doc(userId)
          .collection('list')
          .get();
      return snapshot.docs.map((d) {
        try {
          return MedicationModel.fromJson(d.data());
        } catch (_) {
          return null;
        }
      }).whereType<MedicationModel>().toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      return [];
    }
  }

  /// حساب الجرعات المتوقعة ليوم معين
  int _getExpectedDosesForDay(List<MedicationModel> medications, DateTime date) {
    int expected = 0;
    final checkDate = DateTime(date.year, date.month, date.day);
    for (var med in medications) {
      if (med.frequency == 'as_needed') continue;

      final medStart = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      if (checkDate.isBefore(medStart)) continue;

      if (med.endDate != null) {
        final medEnd = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
        if (checkDate.isAfter(medEnd)) continue;
      }
      
      if (!med.isActive) {
        final medUpdated = DateTime(med.updatedAt.year, med.updatedAt.month, med.updatedAt.day);
        if (checkDate.isAfter(medUpdated)) continue;
      }

      bool shouldTake = false;
      if (med.frequency == 'daily') {
        shouldTake = true;
      } else if (med.frequency == 'alternate_days') {
        final diff = checkDate.difference(medStart).inDays;
        if (diff % 2 == 0) shouldTake = true;
      } else if (med.frequency == 'weekly') {
        if (checkDate.weekday == medStart.weekday) shouldTake = true;
      }

      if (shouldTake) {
        expected += med.times.length;
      }
    }
    return expected;
  }

  /// حساب نسبة الالتزام (Adherence Percentage)
  Future<double> calculateAdherencePercentage(String userId, {int days = 7}) async {
    return await calculateAdherenceRate(userId, days: days);
  }

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

  /// تسجيل الجرعة (تم التناول) وإلغاء التنبيه
  Future<bool> markMedicationAsTaken({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String time,
    int? alarmId, // ⬅️ إضافة alarmId لإلغاء التنبيه
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

      // ⬅️ إلغاء التنبيه الحالي
      if (alarmId != null) {
        await _alarmService.cancelAlarm(
          medicationId,
          scheduledTime,
        );
        debugPrint('✅ Alarm #$alarmId cancelled');
      }

      // ⬅️ جدولة التنبيه لليوم التالي
      final nextDayTime = scheduledTime.add(const Duration(days: 1));
      await _alarmService.scheduleMedicationAlarm(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: '', // يمكنك تمرير الجرعة من المعلمات
        scheduledTime: nextDayTime,
      );
      debugPrint('✅ Next alarm scheduled for ${nextDayTime.hour}:${nextDayTime.minute}');

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

      final taken = snapshot.docs.where((doc) {
        try {
          return doc.data()['status'] == 'taken';
        } catch (e) {
          return false;
        }
      }).length;

      final medications = await _getUserMedications(userId);
      int expectedDoses = 0;

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        expectedDoses += _getExpectedDosesForDay(medications, date);
      }

      if (expectedDoses == 0) {
        final totalLogs = snapshot.docs.length;
        if (totalLogs == 0) return 0.0;
        return (taken / totalLogs) * 100.0;
      }

      final rate = (taken / expectedDoses) * 100;
      final finalRate = rate > 100.0 ? 100.0 : rate;
      
      debugPrint('📊 Adherence Rate: ${finalRate.toStringAsFixed(1)}% ($taken taken / $expectedDoses expected)');
      return finalRate;
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
      final medications = await _getUserMedications(userId);

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final expected = _getExpectedDosesForDay(medications, startOfDay);

        final snapshot = await _firestore
            .collection('adherence_logs')
            .where('userId', isEqualTo: userId)
            .where('scheduledTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('scheduledTime',
            isLessThanOrEqualTo: endOfDay.toIso8601String())
            .get();

        if (expected == 0 && snapshot.docs.isEmpty) {
          continue; // No expected doses and no logs, doesn't break the streak
        }

        final taken = snapshot.docs.where((doc) {
          try {
             return doc.data()['status'] == 'taken';
          } catch(e) {
             return false;
          }
        }).length;

        double dayRate = 0.0;
        if (expected > 0) {
          dayRate = (taken / expected) * 100;
        } else if (snapshot.docs.isNotEmpty) {
          final total = snapshot.docs.length;
          dayRate = (taken / total) * 100;
        }

        if (dayRate >= 80) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      debugPrint('🔥 Current streak: $streak days');
      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating streak: $e');
      return 0;
    }
  }

  /// حساب نسبة الالتزام لدواء معين خلال فترة أيام محددة
  Future<double> calculateMedicationAdherenceRate(String userId, String medicationId, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: userId)
          .where('medicationId', isEqualTo: medicationId)
          .where('scheduledTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('scheduledTime', isLessThanOrEqualTo: now.toIso8601String())
          .get();

      final taken = snapshot.docs.where((doc) {
        try {
          return doc.data()['status'] == 'taken';
        } catch (e) {
          return false;
        }
      }).length;

      final medications = await _getUserMedications(userId);
      final medicationList = medications.where((m) => m.id == medicationId).toList();
      if (medicationList.isEmpty) {
        final totalLogs = snapshot.docs.length;
        if (totalLogs == 0) return 0.0;
        return (taken / totalLogs) * 100.0;
      }

      int expectedDoses = 0;
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        expectedDoses += _getExpectedDosesForDay(medicationList, date);
      }

      if (expectedDoses == 0) {
        final totalLogs = snapshot.docs.length;
        if (totalLogs == 0) return 0.0;
        return (taken / totalLogs) * 100.0;
      }

      final rate = (taken / expectedDoses) * 100.0;
      final finalRate = rate > 100.0 ? 100.0 : rate;

      debugPrint('📊 Medication $medicationId Adherence Rate: ${finalRate.toStringAsFixed(1)}% ($taken taken / $expectedDoses expected)');
      return finalRate;
    } catch (e) {
      debugPrint('❌ Error calculating medication rate: $e');
      return 0.0;
    }
  }

  /// جلب سجل الجرعات لدواء معين
  Future<List<Map<String, dynamic>>> getMedicationLogs(String userId, String medicationId, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: userId)
          .where('medicationId', isEqualTo: medicationId)
          .where('scheduledTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('scheduledTime', isLessThanOrEqualTo: now.toIso8601String())
          .get();

      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort((a, b) {
        final aTime = DateTime.parse(a['scheduledTime'] as String);
        final bTime = DateTime.parse(b['scheduledTime'] as String);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      debugPrint('❌ Error getting medication logs: $e');
      return [];
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