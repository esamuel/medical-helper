import 'package:cloud_firestore/cloud_firestore.dart';

class HealthcareAppointment {
  final String? id;
  final String title;
  final String provider;
  final String speciality;
  final DateTime appointmentDate;
  final String location;
  final String? notes;
  final bool isRecurring;
  final String? recurringPattern;
  final String userId;
  final DateTime createdAt;
  final bool hasReminder;
  final int? reminderMinutes;

  HealthcareAppointment({
    this.id,
    required this.title,
    required this.provider,
    required this.speciality,
    required this.appointmentDate,
    required this.location,
    this.notes,
    this.isRecurring = false,
    this.recurringPattern,
    required this.userId,
    required this.createdAt,
    this.hasReminder = true,
    this.reminderMinutes = 60,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'provider': provider,
      'speciality': speciality,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'location': location,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'userId': userId,
      'hasReminder': hasReminder,
      'reminderMinutes': reminderMinutes,
      // Don't include createdAt here, it will be set by the server
    };
  }

  factory HealthcareAppointment.fromMap(Map<String, dynamic> map, String id) {
    return HealthcareAppointment(
      id: id,
      title: map['title'] ?? '',
      provider: map['provider'] ?? '',
      speciality: map['speciality'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      notes: map['notes'],
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      hasReminder: map['hasReminder'] ?? true,
      reminderMinutes: map['reminderMinutes'] ?? 60,
    );
  }

  HealthcareAppointment copyWith({
    String? id,
    String? title,
    String? provider,
    String? speciality,
    DateTime? appointmentDate,
    String? location,
    String? notes,
    bool? isRecurring,
    String? recurringPattern,
    String? userId,
    DateTime? createdAt,
    bool? hasReminder,
    int? reminderMinutes,
  }) {
    return HealthcareAppointment(
      id: id ?? this.id,
      title: title ?? this.title,
      provider: provider ?? this.provider,
      speciality: speciality ?? this.speciality,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}
