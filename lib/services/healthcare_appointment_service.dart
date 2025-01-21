import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/healthcare_appointment.dart';

class HealthcareAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection = 'healthcare_appointments';

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> addAppointment(HealthcareAppointment appointment) async {
    print('Starting to add appointment'); // Debug print
    try {
      if (_userId.isEmpty) {
        print('Error: User not authenticated (_userId is empty)');
        throw Exception('User not authenticated');
      }

      print('Current user ID: $_userId');
      final data = appointment.toMap();
      print('Appointment data to save: $data'); // Debug print

      // Verify all required fields are present
      if (data['title']?.isEmpty ?? true) {
        throw Exception('Title is required');
      }
      if (data['provider']?.isEmpty ?? true) {
        throw Exception('Provider is required');
      }
      if (data['appointmentDate'] == null) {
        throw Exception('Appointment date is required');
      }

      // Add the document with a specific ID instead of auto-generating
      final docId = _firestore.collection(collection).doc().id;
      await _firestore.collection(collection).doc(docId).set({
        ...data,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Appointment saved with ID: $docId'); // Debug print
      return docId;
    } catch (e, stackTrace) {
      print('Error adding appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> updateAppointment(HealthcareAppointment appointment) async {
    print('Starting to update appointment: ${appointment.id}'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }
      if (appointment.id == null) {
        throw Exception('Appointment ID is required for update');
      }

      final data = appointment.toMap();
      print('Appointment data to update: $data'); // Debug print

      await _firestore.collection(collection).doc(appointment.id).update({
        ...data,
        'userId': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Appointment updated successfully'); // Debug print
    } catch (e, stackTrace) {
      print('Error updating appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    print('Starting to delete appointment: $appointmentId'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(collection).doc(appointmentId).delete();
      print('Appointment deleted successfully'); // Debug print
    } catch (e, stackTrace) {
      print('Error deleting appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Stream<List<HealthcareAppointment>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    print('Getting appointments for user: $_userId'); // Debug print
    try {
      if (_userId.isEmpty) {
        print('No user ID - returning empty stream'); // Debug print
        return Stream.value([]);
      }

      // Simplified query without ordering while index builds
      var query =
          _firestore.collection(collection).where('userId', isEqualTo: _userId);

      return query.snapshots().map((snapshot) {
        print('Received ${snapshot.docs.length} appointments'); // Debug print
        return snapshot.docs.map((doc) {
          final data = doc.data();
          print('Document data: $data'); // Debug print
          return HealthcareAppointment.fromMap(data, doc.id);
        }).where((appointment) {
          final date = appointment.appointmentDate;
          if (startDate != null && date.isBefore(startDate)) return false;
          if (endDate != null && date.isAfter(endDate)) return false;
          return true;
        }).toList()
          ..sort((a, b) =>
              a.appointmentDate.compareTo(b.appointmentDate)); // Sort in memory
      });
    } catch (e, stackTrace) {
      print('Error getting appointments: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      return Stream.value([]);
    }
  }

  Stream<List<HealthcareAppointment>> getUpcomingAppointments() {
    print('Getting upcoming appointments for user: $_userId');
    try {
      if (_userId.isEmpty) {
        print('No user ID - returning empty stream');
        return Stream.value([]);
      }

      final now = DateTime.now();
      print('Current time: $now');
      print('Collection being queried: $collection');
      print('User ID being queried: $_userId');

      var query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('appointmentDate', descending: false);

      print('Query built with parameters:');
      print('- Collection: $collection');
      print('- User ID: $_userId');
      print('- Date filter: >= $now');

      return query.snapshots().map((snapshot) {
        print('Received snapshot with ${snapshot.docs.length} documents');

        if (snapshot.docs.isEmpty) {
          print('No appointments found in snapshot');
          return [];
        }

        print('Processing ${snapshot.docs.length} appointments:');
        final appointments = snapshot.docs
            .map((doc) {
              print('\nProcessing document ${doc.id}:');
              final data = doc.data();
              print('Raw data: $data');

              try {
                final appointment = HealthcareAppointment.fromMap(data, doc.id);
                print('Successfully parsed appointment:');
                print('- Title: ${appointment.title}');
                print('- Date: ${appointment.appointmentDate}');
                print('- Provider: ${appointment.provider}');
                print('- Location: ${appointment.location}');
                return appointment;
              } catch (e, stackTrace) {
                print('Error parsing appointment:');
                print('Error: $e');
                print('Stack trace: $stackTrace');
                return null;
              }
            })
            .where((appointment) => appointment != null)
            .cast<HealthcareAppointment>()
            .toList();

        print('\nFinal processed appointments count: ${appointments.length}');
        if (appointments.isNotEmpty) {
          print('Sample first appointment:');
          print('- Title: ${appointments.first.title}');
          print('- Date: ${appointments.first.appointmentDate}');
        }

        return appointments;
      });
    } catch (e, stackTrace) {
      print('Error in getUpcomingAppointments:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return Stream.value([]);
    }
  }

  Future<List<HealthcareAppointment>> getAppointmentsByProvider(
      String provider) async {
    print('Getting appointments by provider: $provider'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .where('provider', isEqualTo: provider)
          .get();

      print(
          'Received ${snapshot.docs.length} appointments by provider'); // Debug print
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Document data: $data'); // Debug print
        return HealthcareAppointment.fromMap(data, doc.id);
      }).toList();
    } catch (e, stackTrace) {
      print('Error getting appointments by provider: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }
}
