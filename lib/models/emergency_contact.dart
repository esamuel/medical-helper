import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String? id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String? notes;
  final bool isPrimaryContact;
  final DateTime? createdAt;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.notes,
    this.isPrimaryContact = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'notes': notes,
      'isPrimaryContact': isPrimaryContact,
      // Don't convert createdAt - let Firestore handle it
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'],
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      notes: map['notes'],
      isPrimaryContact: map['isPrimaryContact'] ?? false,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    String? notes,
    bool? isPrimaryContact,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 