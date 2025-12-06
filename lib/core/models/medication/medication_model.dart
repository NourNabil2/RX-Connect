import 'package:flutter/material.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart'; // Assumed correct
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart'; // Assumed correct
import 'package:provider/provider.dart';

// ==================== User Model ====================
// (Pasted from your provided code)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // patient, doctor
  final DateTime? dateOfBirth;
  final List<String>? chronicConditions;
  final String? connectedDoctorId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.dateOfBirth,
    this.chronicConditions,
    this.connectedDoctorId,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'chronicConditions': chronicConditions,
      'connectedDoctorId': connectedDoctorId,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      chronicConditions: json['chronicConditions'] != null
          ? List<String>.from(json['chronicConditions'])
          : null,
      connectedDoctorId: json['connectedDoctorId'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// ==================== MedicationModel ====================
// (Pasted from your provided code)
class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String? activeIngredient;
  final String dosage;
  final String frequency; // daily, alternate_days, weekly, as_needed
  final List<String> times; // ["08:00", "14:00", "20:00"]
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.activeIngredient,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.imageUrl,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map (للحفظ في Firebase/SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'activeIngredient': activeIngredient,
      'dosage': dosage,
      'frequency': frequency,
      'times': times.join(','),
      'imageUrl': imageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from Map
  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      activeIngredient: map['activeIngredient'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      times: (map['times'] as String).split(','),
      imageUrl: map['imageUrl'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Convert to JSON (للـ Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'activeIngredient': activeIngredient,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'imageUrl': imageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from JSON
  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      activeIngredient: json['activeIngredient'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      times: List<String>.from(json['times']),
      imageUrl: json['imageUrl'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with
  MedicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? activeIngredient,
    String? dosage,
    String? frequency,
    List<String>? times,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== Adherence Log Model ====================
// (Pasted from your provided code)
class AdherenceLogModel {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // taken, missed, skipped
  final String? notes;

  AdherenceLogModel({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory AdherenceLogModel.fromMap(Map<String, dynamic> map) {
    return AdherenceLogModel(
      id: map['id'],
      userId: map['userId'],
      medicationId: map['medicationId'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      takenTime: map['takenTime'] != null ? DateTime.parse(map['takenTime']) : null,
      status: map['status'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory AdherenceLogModel.fromJson(Map<String, dynamic> json) {
    return AdherenceLogModel(
      id: json['id'],
      userId: json['userId'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime']) : null,
      status: json['status'],
      notes: json['notes'],
    );
  }
}

// ==================== Drug Interaction Model ====================
// (Pasted from your provided code)
class DrugInteractionModel {
  final String id;
  final String drug1;
  final String drug2;
  final String severity; // minor, moderate, major
  final String description;
  final String recommendation;

  DrugInteractionModel({
    required this.id,
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drug1': drug1,
      'drug2': drug2,
      'severity': severity,
      'description': description,
      'recommendation': recommendation,
    };
  }

  factory DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    return DrugInteractionModel(
      id: json['id'],
      drug1: json['drug1'],
      drug2: json['drug2'],
      severity: json['severity'],
      description: json['description'],
      recommendation: json['recommendation'],
    );
  }
}



