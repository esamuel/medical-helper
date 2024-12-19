import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile/profile_screen.dart';

enum BodyCompositionCategory {
  essential,
  athletic,
  fitness,
  acceptable,
  obese
}

enum WaistCircumferenceRisk {
  low,
  moderate,
  high
}

extension WaistCircumferenceRiskExtension on WaistCircumferenceRisk {
  static WaistCircumferenceRisk getRiskForGender(double waistCircumference, Gender gender) {
    switch (gender) {
      case Gender.male:
        if (waistCircumference < 94) return WaistCircumferenceRisk.low;
        if (waistCircumference <= 102) return WaistCircumferenceRisk.moderate;
        return WaistCircumferenceRisk.high;
      
      case Gender.female:
        if (waistCircumference < 80) return WaistCircumferenceRisk.low;
        if (waistCircumference <= 88) return WaistCircumferenceRisk.moderate;
        return WaistCircumferenceRisk.high;
      
      default:
        // For other gender options, use an average
        if (waistCircumference < 87) return WaistCircumferenceRisk.low;
        if (waistCircumference <= 95) return WaistCircumferenceRisk.moderate;
        return WaistCircumferenceRisk.high;
    }
  }

  String get description {
    switch (this) {
      case WaistCircumferenceRisk.low:
        return 'Low Risk';
      case WaistCircumferenceRisk.moderate:
        return 'Moderate Risk';
      case WaistCircumferenceRisk.high:
        return 'High Risk';
    }
  }

  Color get color {
    switch (this) {
      case WaistCircumferenceRisk.low:
        return Colors.green;
      case WaistCircumferenceRisk.moderate:
        return Colors.orange;
      case WaistCircumferenceRisk.high:
        return Colors.red;
    }
  }
}

extension BodyCompositionCategoryExtension on BodyCompositionCategory {
  static BodyCompositionCategory getCategoryForGender(double bodyFatPercentage, Gender gender) {
    switch (gender) {
      case Gender.male:
        if (bodyFatPercentage < 3) return BodyCompositionCategory.essential;
        if (bodyFatPercentage <= 13) return BodyCompositionCategory.athletic;
        if (bodyFatPercentage <= 17) return BodyCompositionCategory.fitness;
        if (bodyFatPercentage <= 25) return BodyCompositionCategory.acceptable;
        return BodyCompositionCategory.obese;
      
      case Gender.female:
        if (bodyFatPercentage < 12) return BodyCompositionCategory.essential;
        if (bodyFatPercentage <= 20) return BodyCompositionCategory.athletic;
        if (bodyFatPercentage <= 24) return BodyCompositionCategory.fitness;
        if (bodyFatPercentage <= 31) return BodyCompositionCategory.acceptable;
        return BodyCompositionCategory.obese;
      
      default:
        if (bodyFatPercentage < 8) return BodyCompositionCategory.essential;
        if (bodyFatPercentage <= 17) return BodyCompositionCategory.athletic;
        if (bodyFatPercentage <= 21) return BodyCompositionCategory.fitness;
        if (bodyFatPercentage <= 28) return BodyCompositionCategory.acceptable;
        return BodyCompositionCategory.obese;
    }
  }

  String get description {
    switch (this) {
      case BodyCompositionCategory.essential:
        return 'Essential Fat';
      case BodyCompositionCategory.athletic:
        return 'Athletic';
      case BodyCompositionCategory.fitness:
        return 'Fitness';
      case BodyCompositionCategory.acceptable:
        return 'Acceptable';
      case BodyCompositionCategory.obese:
        return 'Obese';
    }
  }

  Color get color {
    switch (this) {
      case BodyCompositionCategory.essential:
        return Colors.blue;
      case BodyCompositionCategory.athletic:
        return Colors.green;
      case BodyCompositionCategory.fitness:
        return Colors.teal;
      case BodyCompositionCategory.acceptable:
        return Colors.orange;
      case BodyCompositionCategory.obese:
        return Colors.red;
    }
  }
}

class BodyCompositionReading {
  final String id;
  final double fatMassKg;
  final double fatMassPercentage;
  final double leanMassKg;
  final double leanMassPercentage;
  final double bodyWaterPercentage;
  final double visceralFatLevel;
  final double waistCircumference; // in centimeters
  final DateTime timestamp;
  final String notes;
  final Gender gender;

  BodyCompositionReading({
    required this.id,
    required this.fatMassKg,
    required this.fatMassPercentage,
    required this.leanMassKg,
    required this.leanMassPercentage,
    required this.bodyWaterPercentage,
    required this.visceralFatLevel,
    required this.waistCircumference,
    required this.timestamp,
    required this.gender,
    this.notes = '',
  });

  BodyCompositionCategory get category {
    return BodyCompositionCategoryExtension.getCategoryForGender(
      fatMassPercentage,
      gender,
    );
  }

  WaistCircumferenceRisk get waistRisk {
    return WaistCircumferenceRiskExtension.getRiskForGender(
      waistCircumference,
      gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fatMassKg': fatMassKg,
      'fatMassPercentage': fatMassPercentage,
      'leanMassKg': leanMassKg,
      'leanMassPercentage': leanMassPercentage,
      'bodyWaterPercentage': bodyWaterPercentage,
      'visceralFatLevel': visceralFatLevel,
      'waistCircumference': waistCircumference,
      'timestamp': timestamp,
      'notes': notes,
      'gender': gender.toString(),
    };
  }

  factory BodyCompositionReading.fromMap(Map<String, dynamic> map) {
    return BodyCompositionReading(
      id: map['id'],
      fatMassKg: map['fatMassKg'].toDouble(),
      fatMassPercentage: map['fatMassPercentage'].toDouble(),
      leanMassKg: map['leanMassKg'].toDouble(),
      leanMassPercentage: map['leanMassPercentage'].toDouble(),
      bodyWaterPercentage: map['bodyWaterPercentage'].toDouble(),
      visceralFatLevel: map['visceralFatLevel'].toDouble(),
      waistCircumference: map['waistCircumference'].toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
      gender: Gender.values.firstWhere(
        (e) => e.toString() == map['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
    );
  }
}
