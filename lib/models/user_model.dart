class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? bloodType;
  final DateTime dateOfBirth;
  final List<String> allergies;
  final List<String> medications;
  final String? insuranceProvider;
  final String? insuranceNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    this.phoneNumber,
    this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.insuranceProvider,
    this.insuranceNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'bloodType': bloodType,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'allergies': allergies,
      'medications': medications,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      bloodType: map['bloodType'],
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      insuranceProvider: map['insuranceProvider'],
      insuranceNumber: map['insuranceNumber'],
    );
  }
} 