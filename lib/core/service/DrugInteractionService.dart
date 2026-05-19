import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:pharmacist_assistant/core/db/database_helper.dart';
import 'package:pharmacist_assistant/core/db/reference_database_helper.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';

class DrugInteractionService {
  final ReferenceDatabaseHelper _referenceDb;

  DrugInteractionService({ReferenceDatabaseHelper? referenceDb})
      : _referenceDb = referenceDb ?? ReferenceDatabaseHelper();

  final DatabaseHelper _localDb = DatabaseHelper();

  static Map<String, List<Map<String, dynamic>>>? _interactionsCache;

  Future<List<Map<String, dynamic>>> searchMedications(String query) async {
    if (query.trim().length < 2) return [];
    return _referenceDb.searchTradeNames(query);
  }

  Future<List<Map<String, dynamic>>> getPopularMedications() async {
    return _referenceDb.getAllTradeNames(limit: 50);
  }

  Future<String?> resolveActiveIngredient(String tradeName) async {
    final String? ingredientId = await _referenceDb.resolveTradeName(tradeName);
    if (ingredientId == null) return null;
    return _referenceDb.getActiveIngredientName(ingredientId);
  }

  Future<List<DrugInteractionModel>> checkInteractions({
    required String newMedicationName,
    String? newActiveIngredient,
    required List<MedicationModel> currentMedications,
  }) async {
    final List<DrugInteractionModel> detected = [];

    try {
      developer.log('🔬 DDI Engine: Analyzing "$newMedicationName"...', name: 'DrugInteractionService');

      // ⬅️ String بدل int
      final String? newIngredientId = await _resolveIngredientId(
        tradeName: newMedicationName,
        activeIngredient: newActiveIngredient,
      );

      if (newIngredientId == null) {
        developer.log('⚠️ DDI Engine: Not found in formulary. Skipping.', name: 'DrugInteractionService');
        return detected;
      }

      final Map<String, dynamic>? newIngredientRow = await _referenceDb.getActiveIngredient(newIngredientId);
      final String newIngredientName = (newIngredientRow?['name'] as String?) ?? newMedicationName;

      for (final MedicationModel currentMed in currentMedications) {
        if (currentMed.name.trim().toLowerCase() == newMedicationName.trim().toLowerCase()) {
          continue;
        }

        // ⬅️ String بدل int
        final String? currentIngredientId = await _resolveIngredientId(
          tradeName: currentMed.name,
          activeIngredient: currentMed.activeIngredient,
        );

        if (currentIngredientId == null) continue;
        if (currentIngredientId == newIngredientId) continue;

        final List<Map<String, dynamic>> interactionRows = await _referenceDb.findInteractions(newIngredientId, currentIngredientId);

        for (final row in interactionRows) {
          final String severity = (row['severity'] as String).toLowerCase();
          final String description = (row['description'] as String?) ?? 'تفاعل دوائي محتمل';

          detected.add(DrugInteractionModel(
            id: row['id'].toString(),
            drug1: newMedicationName,
            drug2: currentMed.name,
            severity: severity,
            description: '$newIngredientName ↔ ${currentMed.activeIngredient ?? currentMed.name}: $description',
            recommendation: _clinicalRecommendation(severity),
          ));
        }
      }

      developer.log('✅ DDI Engine: ${detected.length} interaction(s) detected.', name: 'DrugInteractionService');
      return detected;
    } catch (e, stackTrace) {
      developer.log('❌ DDI Engine: Critical failure', error: e, stackTrace: stackTrace);
      return detected;
    }
  }

  static String getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
      case 'severe':
        return '#F44336';
      case 'moderate':
        return '#FF9800';
      case 'minor':
        return '#FFC107';
      default:
        return '#9E9E9E';
    }
  }

  static String getSeverityTextAr(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
      case 'severe':
        return 'خطير';
      case 'moderate':
        return 'متوسط';
      case 'minor':
        return 'بسيط';
      default:
        return 'غير معروف';
    }
  }

  // ⬅️ String بدل int
  Future<String?> _resolveIngredientId({
    required String tradeName,
    String? activeIngredient,
  }) async {
    if (activeIngredient != null && activeIngredient.trim().isNotEmpty) {
      final String? id = await _referenceDb.getActiveIngredientIdByName(activeIngredient);
      if (id != null) return id;
    }
    return _referenceDb.resolveTradeName(tradeName);
  }

  String _clinicalRecommendation(String severity) {
    return switch (severity.toLowerCase()) {
      'major' => '⛔ تفاعل دوائي خطير: يُمنع الاستخدام المشترك. استشر الطبيب فوراً.',
      'moderate' => '⚠️ تفاعل متوسط: يُنصح باستشارة الطبيب قبل الاستخدام المشترك.',
      'minor' => 'ℹ️ تفاعل بسيط: خطره عادةً محدود. راقب الأعراض واستشر الصيدلي.',
      _ => 'استشر الطبيب أو الصيدلي لمزيد من المعلومات.',
    };
  }
}