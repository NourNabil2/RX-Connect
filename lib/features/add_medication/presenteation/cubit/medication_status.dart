import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/service/DrugInteractionService.dart';
import 'package:pharmacist_assistant/features/alarm/service/medication_alarm_service.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/database_helper.dart';
import '../../../auth/presentaion/cubit/auth_status.dart';

enum MedicationStatus { idle, loading, success, error }

class MedicationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _localDb = DatabaseHelper();
  final DrugInteractionService _interactionService = DrugInteractionService();
  final MedicationAlarmService _alarmService = MedicationAlarmService();
  final Uuid _uuid = const Uuid();

  MedicationStatus _status = MedicationStatus.idle;
  List<MedicationModel> _medications = [];
  List<DrugInteractionModel> _detectedInteractions = [];
  String? _errorMessage;

  // Getters
  MedicationStatus get status => _status;
  List<MedicationModel> get medications => _medications;
  List<DrugInteractionModel> get detectedInteractions => _detectedInteractions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == MedicationStatus.loading;
  bool get hasInteractions => _detectedInteractions.isNotEmpty;

  /// Load Medications
  Future<void> loadMedications(String userId, {bool force = false}) async {
    // منع التحميل المكرر
    if (!force && _status == MedicationStatus.loading) return;

    try {
      _status = MedicationStatus.loading;
      notifyListeners();

      // 1. تحميل من Local DB فوراً (سريع جداً)
      final localMeds = await _localDb.getAllMedications(userId);
      _medications = localMeds.map((m) => MedicationModel.fromMap(m)).toList();
      _status = MedicationStatus.success;
      notifyListeners();
      debugPrint('✅ Loaded ${_medications.length} from cache');

      // 2. Sync مع Firestore في الخلفية (بدون await)
      _syncWithFirestore(userId);

    } catch (e) {
      debugPrint('❌ Error: $e');
      _status = MedicationStatus.error;
      _errorMessage = 'خطأ في التحميل';
      notifyListeners();
    }
  }

  /// Sync في الخلفية بدون blocking
  Future<void> _syncWithFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('medications')
          .doc(userId)
          .collection('list')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final cloudMeds = snapshot.docs
          .map((doc) {
        try {
          return MedicationModel.fromJson(doc.data());
        } catch (e) {
          return null;
        }
      })
          .whereType<MedicationModel>()
          .toList();

      // تحديث فقط لو في تغيير
      if (_hasChanged(_medications, cloudMeds)) {
        _medications = cloudMeds;

        // حفظ في Local DB
        for (var med in cloudMeds) {
          await _localDb.insertMedication(med.toMap());
        }

        notifyListeners();
        debugPrint('🔄 Synced ${cloudMeds.length} from cloud');
      }
    } catch (e) {
      debugPrint('⚠️ Cloud sync failed: $e');
    }
  }

  /// تحقق من التغيير
  bool _hasChanged(List<MedicationModel> old, List<MedicationModel> new_) {
    if (old.length != new_.length) return true;

    for (int i = 0; i < old.length; i++) {
      if (old[i].id != new_[i].id ||
          old[i].updatedAt != new_[i].updatedAt) {
        return true;
      }
    }

    return false;
  }
  /// Check Drug Interactions
  Future<List<DrugInteractionModel>> checkInteractions(
      String newMedicationName,
      String? activeIngredient, {
        String? excludeMedicationId,
      }) async {
    _detectedInteractions.clear();

    try {
      debugPrint('🔍 Checking interactions for: $newMedicationName');

      // Filter out the medication being updated (if any)
      final List<MedicationModel> currentMeds = excludeMedicationId != null
          ? _medications.where((m) => m.id != excludeMedicationId).toList()
          : List.unmodifiable(_medications);

      debugPrint('Current medications: ${currentMeds.map((m) => m.name).toList()}');

      final interactions = await _interactionService.checkInteractions(
        newMedicationName: newMedicationName,
        newActiveIngredient: activeIngredient,
        currentMedications: currentMeds,
      );

      _detectedInteractions = interactions;
      debugPrint('⚠️ Found ${interactions.length} interactions');

      notifyListeners();
      return interactions;
    } catch (e) {
      debugPrint('❌ Error checking interactions: $e');
      return [];
    }
  }

  /// Update existing medication
  Future<bool> updateMedication(MedicationModel updatedMedication) async {
    try {
      _status = MedicationStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📝 Updating medication: ${updatedMedication.id}');

      final userId = updatedMedication.userId;
      final medicationId = updatedMedication.id;

      // 1. Check interactions again
      final originalMed = _medications.firstWhere((m) => m.id == medicationId);
      final nameChanged = originalMed.name.toLowerCase() != updatedMedication.name.toLowerCase();
      final ingredientChanged = (originalMed.activeIngredient ?? '') != (updatedMedication.activeIngredient ?? '');

      if (nameChanged || ingredientChanged) {
        final interactions = await checkInteractions(
          updatedMedication.name,
          updatedMedication.activeIngredient,
          excludeMedicationId: medicationId,
        );

        final severe = interactions.where((i) => i.severity == 'major' || i.severity == 'severe').toList();
        if (severe.isNotEmpty) {
          _status = MedicationStatus.error;
          _errorMessage = 'تحذير: تفاعل دوائي خطير بعد التعديل!';
          notifyListeners();
          return false;
        }
      }

      // 2. Update in Firestore
      final docRef = _firestore
          .collection('medications')
          .doc(userId)
          .collection('list')
          .doc(medicationId);

      final updatedData = updatedMedication.copyWith(
        updatedAt: DateTime.now(),
      ).toJson();

      await docRef.update(updatedData);
      debugPrint('✅ Updated in Firestore');

      // 3. Update local DB
      try {
        await _localDb.updateMedication(updatedMedication.toMap());
        debugPrint('✅ Updated in local DB');
      } catch (e) {
        debugPrint('⚠️ Local DB update failed (non-critical): $e');
      }

      // 4. Cancel old alarms ⬅️ استخدام Alarm
      await _cancelMedicationAlarms(medicationId, originalMed.times);

      // 5. Schedule new alarms ⬅️ استخدام Alarm
      await _scheduleMedicationAlarms(updatedMedication);

      // 6. Reload medications
      await loadMedications(userId, force: true);

      _status = MedicationStatus.success;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating medication: $e');
      debugPrint('Stack: $stackTrace');
      _status = MedicationStatus.error;
      _errorMessage = 'فشل تحديث الدواء: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add Medication
  Future<bool> addMedication({
    required String userId,
    required String name,
    String? activeIngredient,
    required String dosage,
    required String frequency,
    required List<String> times,
    String? imageUrl,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      _status = MedicationStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('💊 Adding medication: $name for user: $userId');

      // 1. Check for drug interactions
      final interactions = await checkInteractions(name, activeIngredient);
      final severeInteractions = interactions
          .where((i) => i.severity == 'major' || i.severity == 'severe')
          .toList();

      if (severeInteractions.isNotEmpty) {
        debugPrint('❌ Severe interactions found - blocking save');
        _status = MedicationStatus.error;
        _errorMessage = 'تحذير: تفاعل دوائي خطير! يُرجى استشارة الطبيب';
        notifyListeners();
        return false;
      }

      // 2. Create medication
      final medicationId = _uuid.v4();
      final now = DateTime.now();

      final medication = MedicationModel(
        id: medicationId,
        userId: userId,
        name: name,
        activeIngredient: activeIngredient,
        dosage: dosage,
        frequency: frequency,
        times: times,
        imageUrl: imageUrl,
        startDate: now,
        endDate: endDate,
        notes: notes,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // 3. Save to Firestore
      try {
        final docRef = _firestore
            .collection('medications')
            .doc(userId)
            .collection('list')
            .doc(medicationId);

        await docRef.set(medication.toJson());
        debugPrint('✅ Saved to Firestore');
      } catch (firestoreError) {
        debugPrint('❌ Firestore save error: $firestoreError');
        _status = MedicationStatus.error;
        _errorMessage = 'فشل حفظ الدواء في السحابة';
        notifyListeners();
        return false;
      }

      // 4. Save to Local DB
      try {
        await _localDb.insertMedication(medication.toMap());
        debugPrint('✅ Saved to local DB');
      } catch (localError) {
        debugPrint('⚠️ Local DB save error (non-critical): $localError');
      }

      // 5. Schedule alarms 🔔 ⬅️ استخدام Alarm
      await _scheduleMedicationAlarms(medication);

      // 6. Notify doctor if interactions
      if (interactions.isNotEmpty) {
        try {
          await _notifyDoctorAboutInteraction(userId, medication, interactions);
          debugPrint('✅ Notified doctor about interactions');
        } catch (e) {
          debugPrint('⚠️ Failed to notify doctor: $e');
        }
      }

      // 7. Reload medications
      await loadMedications(userId, force: true);

      _status = MedicationStatus.success;
      debugPrint('✅ Medication added successfully!');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error in addMedication: $e');
      debugPrint('Stack trace: $stackTrace');
      _status = MedicationStatus.error;
      _errorMessage = 'فشل إضافة الدواء: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Schedule alarms for a medication ⬅️ استخدام Alarm بدلاً من Notifications
  Future<void> _scheduleMedicationAlarms(MedicationModel medication) async {
    try {
      debugPrint('📅 Scheduling alarms for: ${medication.name}');

      await _alarmService.scheduleMedicationAlarms(
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: medication.dosage,
        times: medication.times,
        imageUrl: medication.imageUrl,
      );

      debugPrint('✅ All alarms scheduled successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule alarms: $e');
    }
  }

  /// Cancel all alarms for a medication ⬅️ استخدام Alarm
  Future<void> _cancelMedicationAlarms(String medicationId, List<String> times) async {
    try {
      debugPrint('🔕 Cancelling alarms for: $medicationId');

      await _alarmService.cancelMedicationAlarms(medicationId, times);

      debugPrint('✅ Cancelled all alarms');
    } catch (e) {
      debugPrint('⚠️ Failed to cancel alarms: $e');
    }
  }

  /// Delete Medication
  Future<bool> deleteMedication(BuildContext context, String medicationId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;

    if (userId == null) {
      _errorMessage = 'المستخدم غير مسجل الدخول';
      notifyListeners();
      return false;
    }

    try {
      // Find medication to get times
      final medication = _medications.firstWhere((m) => m.id == medicationId);

      // Cancel alarms ⬅️ استخدام Alarm
      await _cancelMedicationAlarms(medicationId, medication.times);

      // Soft delete in Firestore
      await _firestore
          .collection('medications')
          .doc(userId)
          .collection('list')
          .doc(medicationId)
          .update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Delete from local DB
      await _localDb.deleteMedication(medicationId);

      // Reload
      await loadMedications(userId, force: true);

      debugPrint('✅ Deleted medication: $medicationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting medication: $e');
      _errorMessage = 'فشل الحذف';
      notifyListeners();
      return false;
    }
  }

  /// Get Today's Medications
  List<MedicationModel> getTodaysMedications() {
    final now = DateTime.now();
    return _medications.where((med) {
      if (!med.isActive) return false;
      if (med.endDate != null && med.endDate!.isBefore(now)) return false;

      if (med.frequency == 'daily') return true;
      if (med.frequency == 'alternate_days') {
        final daysDiff = now.difference(med.startDate).inDays;
        return daysDiff % 2 == 0;
      }
      if (med.frequency == 'weekly') {
        return now.weekday == med.startDate.weekday;
      }

      return false;
    }).toList();
  }

  /// Notify Doctor about Interaction via Chat
  Future<void> _notifyDoctorAboutInteraction(
      String userId,
      MedicationModel medication,
      List<DrugInteractionModel> interactions,
      ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final patientName = userDoc.data()?['name'] ?? 'مريض';

      // Get all doctors this patient is connected to
      final chatsQuery = await _firestore
          .collection('chats')
          .where('patientId', isEqualTo: userId)
          .get();

      if (chatsQuery.docs.isEmpty) {
        debugPrint('⚠️ No connected doctors found to notify');
        return;
      }

      final chatProvider = ChatProvider();
      
      // Send conflict alert to ALL connected doctors
      for (var doc in chatsQuery.docs) {
        final doctorId = doc.data()['doctorId'] as String?;
        if (doctorId != null) {
          await chatProvider.sendConflictAlert(
            patientId: userId,
            patientName: patientName,
            doctorId: doctorId,
            medicationName: medication.name,
            interactions: interactions.map((i) => i.toJson()).toList(),
          );
        }
      }

      debugPrint('✅ Conflict alert sent to all doctor chats (${chatsQuery.docs.length} doctors)');
    } catch (e) {
      debugPrint('⚠️ Error notifying doctors via chat: $e');
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _detectedInteractions.clear();
    notifyListeners();
  }
}