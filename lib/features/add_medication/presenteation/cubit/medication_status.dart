import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/service/DrugInteractionService.dart';
import 'package:pharmacist_assistant/core/service/notification_helper.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/database_helper.dart';
import '../../../auth/presentaion/cubit/auth_status.dart';

enum MedicationStatus { idle, loading, success, error }

class MedicationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _localDb = DatabaseHelper();
  final DrugInteractionService _interactionService = DrugInteractionService();
  final NotificationService _notificationService = NotificationService();
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
  Future<void> loadMedications(String userId) async {
    try {
      _status = MedicationStatus.loading;
      notifyListeners();

      debugPrint('📥 Loading medications for user: $userId');

      // Load from local DB first
      try {
        final localMeds = await _localDb.getAllMedications(userId);
        _medications = localMeds.map((m) => MedicationModel.fromMap(m)).toList();
        debugPrint('✅ Loaded ${_medications.length} medications from local DB');
        notifyListeners();
      } catch (localError) {
        debugPrint('⚠️ Local DB error (non-critical): $localError');
      }

      // Sync with Firestore
      try {
        final snapshot = await _firestore
            .collection('medications')
            .doc(userId)
            .collection('list')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        debugPrint('✅ Firestore returned ${snapshot.docs.length} medications');

        _medications = snapshot.docs
            .map((doc) {
          try {
            return MedicationModel.fromJson(doc.data());
          } catch (e) {
            debugPrint('⚠️ Error parsing medication ${doc.id}: $e');
            return null;
          }
        })
            .whereType<MedicationModel>()
            .toList();

        debugPrint('✅ Successfully parsed ${_medications.length} medications');

        // Update local DB
        for (var med in _medications) {
          try {
            await _localDb.insertMedication(med.toMap());
          } catch (e) {
            debugPrint('⚠️ Error saving to local DB: $e');
          }
        }

        _status = MedicationStatus.success;
      } catch (firestoreError) {
        debugPrint('❌ Firestore error: $firestoreError');
        _status = MedicationStatus.error;
        _errorMessage = 'فشل تحميل الأدوية من السحابة';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Critical error in loadMedications: $e');
      _status = MedicationStatus.error;
      _errorMessage = 'خطأ في تحميل الأدوية: $e';
      notifyListeners();
    }
  }

  /// Check Drug Interactions
  Future<List<DrugInteractionModel>> checkInteractions(
      String newMedicationName,
      String? activeIngredient,
      ) async {
    _detectedInteractions.clear();

    try {
      debugPrint('🔍 Checking interactions for: $newMedicationName');

      final currentMedNames = _medications.map((m) => m.name.toLowerCase()).toList();
      debugPrint('Current medications: $currentMedNames');

      final interactions = await _interactionService.checkInteractions(
        newMedicationName,
        activeIngredient,
        currentMedNames,
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

      // 4. Cancel old notifications
      await _cancelMedicationNotifications(medicationId);

      // 5. Schedule new notifications
      await _scheduleMedicationNotifications(updatedMedication);

      // 6. Reload medications
      await loadMedications(userId);

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

      // 5. Schedule notifications 🔔
      await _scheduleMedicationNotifications(medication);

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
      await loadMedications(userId);

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

  /// Schedule notifications for a medication
  Future<void> _scheduleMedicationNotifications(MedicationModel medication) async {
    try {
      debugPrint('📅 Scheduling notifications for: ${medication.name}');

      for (int i = 0; i < medication.times.length; i++) {
        final timeStr = medication.times[i];
        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final notificationId = _generateNotificationId(medication.id, i);

        await _notificationService.scheduleDailyReminder(
          id: notificationId,
          title: '💊 تذكير بتناول الدواء',
          body: '${medication.name} - ${medication.dosage}\n⏰ الوقت: $timeStr',
          time: TimeOfDay(hour: hour, minute: minute),
        );

        debugPrint('✅ Scheduled notification #$notificationId for $timeStr');
      }

      debugPrint('✅ All notifications scheduled successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule notifications: $e');
      // Don't fail the whole operation
    }
  }

  /// Cancel all notifications for a medication
  Future<void> _cancelMedicationNotifications(String medicationId) async {
    try {
      debugPrint('🔕 Cancelling notifications for: $medicationId');

      for (int i = 0; i < 10; i++) {
        final notifId = _generateNotificationId(medicationId, i);
        await _notificationService.cancelReminder(notifId);
      }

      debugPrint('✅ Cancelled all notifications');
    } catch (e) {
      debugPrint('⚠️ Failed to cancel notifications: $e');
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
      // Cancel notifications
      await _cancelMedicationNotifications(medicationId);

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
      await loadMedications(userId);

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

  /// Generate unique notification ID
  int _generateNotificationId(String medicationId, int timeIndex) {
    final hash = medicationId.hashCode.abs() % 100000;
    return hash * 10 + timeIndex;
  }

  /// Notify Doctor about Interaction
  Future<void> _notifyDoctorAboutInteraction(
      String userId,
      MedicationModel medication,
      List<DrugInteractionModel> interactions,
      ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final doctorId = userDoc.data()?['connectedDoctorId'];

      if (doctorId == null) {
        debugPrint('⚠️ No connected doctor found');
        return;
      }

      await _firestore.collection('notifications').doc().set({
        'doctorId': doctorId,
        'patientId': userId,
        'type': 'drug_interaction_warning',
        'medicationName': medication.name,
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      debugPrint('⚠️ Error notifying doctor: $e');
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _detectedInteractions.clear();
    notifyListeners();
  }
}