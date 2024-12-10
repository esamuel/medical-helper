import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MedicationFrequency {
  daily,
  twiceDaily,
  thriceDaily,
  weekly,
  asNeeded
}

class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final String instructions;
  final DateTime startDate;
  final String userId;
  final TimeOfDay defaultTime;

  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.instructions,
    required this.startDate,
    required this.userId,
    required this.defaultTime,
  });

  String get frequencyText {
    switch (frequency) {
      case MedicationFrequency.daily:
        return 'Once daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice daily';
      case MedicationFrequency.thriceDaily:
        return 'Three times daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.asNeeded:
        return 'As needed';
    }
  }

  List<TimeOfDay> get takingTimes {
    if (frequency == MedicationFrequency.asNeeded) {
      return [];
    }

    switch (frequency) {
      case MedicationFrequency.daily:
        return [defaultTime];
      case MedicationFrequency.twiceDaily:
        return [
          defaultTime,
          TimeOfDay(
            hour: (defaultTime.hour + 12) % 24,
            minute: defaultTime.minute,
          ),
        ];
      case MedicationFrequency.thriceDaily:
        return [
          defaultTime,
          TimeOfDay(
            hour: (defaultTime.hour + 8) % 24,
            minute: defaultTime.minute,
          ),
          TimeOfDay(
            hour: (defaultTime.hour + 16) % 24,
            minute: defaultTime.minute,
          ),
        ];
      case MedicationFrequency.weekly:
        return [defaultTime];
      default:
        return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency.index,
      'instructions': instructions,
      'startDate': Timestamp.fromDate(startDate),
      'userId': userId,
      'defaultTime': '${defaultTime.hour.toString().padLeft(2, '0')}:${defaultTime.minute.toString().padLeft(2, '0')}',
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map, String docId) {
    final timestamp = map['startDate'] as Timestamp;
    final timeStr = map['defaultTime'] as String;
    final timeParts = timeStr.split(':');
    final defaultTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return MedicationModel(
      id: docId,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: MedicationFrequency.values[map['frequency'] as int],
      instructions: map['instructions'] as String? ?? '',
      startDate: timestamp.toDate(),
      userId: map['userId'] as String,
      defaultTime: defaultTime,
    );
  }

  String formatTakingTimes() {
    if (frequency == MedicationFrequency.asNeeded) {
      return 'As needed';
    }
    return takingTimes.map((time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }).join(', ');
  }

  MedicationModel copyWith({
    String? id,
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    String? instructions,
    DateTime? startDate,
    String? userId,
    TimeOfDay? defaultTime,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      userId: userId ?? this.userId,
      defaultTime: defaultTime ?? this.defaultTime,
    );
  }
} 