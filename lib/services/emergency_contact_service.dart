import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';

class EmergencyContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _contactsCollection =>
      _firestore.collection('emergency_contacts');

  Future<EmergencyContact> addContact(EmergencyContact contact) async {
    print('Adding contact for user: $_userId'); // Debug print
    
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'relationship': contact.relationship,
        'notes': contact.notes,
        'isPrimaryContact': contact.isPrimaryContact,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('Contact data to be added: $data'); // Debug print

      final docRef = await _contactsCollection.add(data);
      print('Contact added with ID: ${docRef.id}'); // Debug print
      
      // Get the created document with the server timestamp
      final newDoc = await docRef.get();
      final newData = newDoc.data();
      print('New document data: $newData'); // Debug print
      
      if (newData != null) {
        return EmergencyContact.fromMap({
          ...newData,
          'id': docRef.id,
        });
      } else {
        throw Exception('Failed to create contact: No data returned');
      }
    } catch (e) {
      print('Error adding contact: $e'); // Debug print
      rethrow;
    }
  }

  Stream<List<EmergencyContact>> getContacts() {
    print('Getting contacts for user: $_userId'); // Debug print
    
    if (_userId.isEmpty) {
      print('No user ID - returning empty list'); // Debug print
      return Stream.value([]);
    }

    try {
      return _contactsCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Query parameters - userId: $_userId'); // Debug print
            print('Query parameters - collection: emergency_contacts'); // Debug print
            print('Snapshot metadata - fromCache: ${snapshot.metadata.isFromCache}'); // Debug print
            print('Snapshot metadata - hasPendingWrites: ${snapshot.metadata.hasPendingWrites}'); // Debug print
            print('Received ${snapshot.docs.length} contacts'); // Debug print
            
            final contacts = snapshot.docs.map((doc) {
              final data = doc.data();
              print('Document ID: ${doc.id}'); // Debug print
              print('Contact data from Firestore: $data'); // Debug print
              
              return EmergencyContact.fromMap({
                ...data,
                'id': doc.id,
              });
            }).toList();

            return contacts;
          });
    } catch (e) {
      print('Error getting contacts: $e'); // Debug print
      return Stream.value([]);
    }
  }

  Future<void> updateContact(EmergencyContact contact) async {
    print('Updating contact: ${contact.id}'); // Debug print
    
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    if (contact.id == null) {
      throw Exception('Contact ID is required for update');
    }

    try {
      final data = {
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'relationship': contact.relationship,
        'notes': contact.notes,
        'isPrimaryContact': contact.isPrimaryContact,
        'userId': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Update data: $data'); // Debug print
      await _contactsCollection.doc(contact.id).update(data);
      print('Contact updated successfully'); // Debug print
    } catch (e) {
      print('Error updating contact: $e'); // Debug print
      rethrow;
    }
  }

  Future<void> deleteContact(String contactId) async {
    print('Deleting contact: $contactId'); // Debug print
    
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    try {
      await _contactsCollection.doc(contactId).delete();
      print('Contact deleted successfully'); // Debug print
    } catch (e) {
      print('Error deleting contact: $e'); // Debug print
      rethrow;
    }
  }
} 