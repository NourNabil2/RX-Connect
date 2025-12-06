import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pharmacist_assistant/core/db/database_helper.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';

class DrugInteractionService {
  final DatabaseHelper _localDb = DatabaseHelper();

  // Local interactions database cache
  static Map<String, List<Map<String, dynamic>>>? _interactionsCache;

  // Load interactions from local JSON file
  Future<void> _loadInteractionsDatabase() async {
    if (_interactionsCache != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/interactions_data.json');
      final List<dynamic> data = json.decode(jsonString);

      _interactionsCache = {};

      for (var item in data) {
        final drug = item['drug'].toString().toLowerCase();
        if (!_interactionsCache!.containsKey(drug)) {
          _interactionsCache![drug] = [];
        }
        _interactionsCache![drug]!.add(item);
      }
    } catch (e) {
      _interactionsCache = {};
    }
  }

  // Check for drug-drug interactions
  Future<List<DrugInteractionModel>> checkInteractions(
      String newMedicationName,
      String? activeIngredient,
      List<String> currentMedications,
      ) async {
    await _loadInteractionsDatabase();

    List<DrugInteractionModel> interactions = [];
    final newDrug = newMedicationName.toLowerCase();
    final newIngredient = activeIngredient?.toLowerCase();

    // Check each current medication
    for (var currentMed in currentMedications) {
      final currentDrug = currentMed.toLowerCase();

      // Check drug name interactions
      final interaction = _checkPairInteraction(newDrug, currentDrug);
      if (interaction != null) {
        interactions.add(interaction);
      }

      // Check active ingredient interactions
      if (newIngredient != null) {
        final ingredientInteraction = _checkPairInteraction(newIngredient, currentDrug);
        if (ingredientInteraction != null) {
          interactions.add(ingredientInteraction);
        }
      }
    }

    // Cache results in local DB
    for (var interaction in interactions) {
      await _localDb.cacheInteraction(interaction.toJson());
    }

    return interactions;
  }

  // Check interaction between two drugs
  DrugInteractionModel? _checkPairInteraction(String drug1, String drug2) {
    if (_interactionsCache == null) return null;

    // Check drug1 -> drug2
    if (_interactionsCache!.containsKey(drug1)) {
      for (var item in _interactionsCache![drug1]!) {
        if (item['interactsWith'].toString().toLowerCase() == drug2) {
          return DrugInteractionModel(
            id: '${drug1}_$drug2',
            drug1: drug1,
            drug2: drug2,
            severity: item['severity'] ?? 'moderate',
            description: item['description'] ?? 'قد يتفاعل هذا الدواء',
            recommendation: item['recommendation'] ?? 'استشر الطبيب',
          );
        }
      }
    }

    // Check drug2 -> drug1
    if (_interactionsCache!.containsKey(drug2)) {
      for (var item in _interactionsCache![drug2]!) {
        if (item['interactsWith'].toString().toLowerCase() == drug1) {
          return DrugInteractionModel(
            id: '${drug2}_$drug1',
            drug1: drug2,
            drug2: drug1,
            severity: item['severity'] ?? 'moderate',
            description: item['description'] ?? 'قد يتفاعل هذا الدواء',
            recommendation: item['recommendation'] ?? 'استشر الطبيب',
          );
        }
      }
    }

    return null;
  }

  // Get interaction severity color
  static String getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
      case 'severe':
        return '#F44336'; // Red
      case 'moderate':
        return '#FF9800'; // Orange
      case 'minor':
        return '#FFC107'; // Yellow
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get interaction severity text (Arabic)
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
}