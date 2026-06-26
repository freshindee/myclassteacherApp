import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/contact_model.dart';

abstract class ContactRemoteDataSource {
  Future<List<ContactModel>> getContacts(String schoolId);
  Future<ContactModel?> getContactById(String schoolId, String contactId);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final FirebaseFirestore firestore;

  ContactRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<ContactModel>> getContacts(String schoolId) async {
    try {
      print('📞 [API REQUEST] ContactDataSource.getContacts called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('contacts')
          .get();
      
      print('📞 [API RESPONSE] Found ${querySnapshot.docs.length} contact documents for schoolId: $schoolId');
      
      final contacts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📞 [API RESPONSE] Contact document ${doc.id}: $data');
        return ContactModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📞 [API RESPONSE] Successfully parsed ${contacts.length} contacts');
      return contacts;
    } catch (e) {
      print('📞 [API ERROR] Error fetching contacts: $e');
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  @override
  Future<ContactModel?> getContactById(String schoolId, String contactId) async {
    try {
      print('📞 [API REQUEST] ContactDataSource.getContactById called with schoolId: $schoolId, contactId: $contactId');
      
      final doc = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('contacts')
          .doc(contactId)
          .get();
      
      if (!doc.exists) {
        print('📞 [API RESPONSE] Contact document not found for contactId: $contactId');
        return null;
      }
      
      final data = doc.data()!;
      print('📞 [API RESPONSE] Contact document ${doc.id}: $data');
      
      final contact = ContactModel.fromJson({
        'id': doc.id,
        ...data,
      });
      
      print('📞 [API RESPONSE] Successfully parsed contact: ${contact.name}');
      return contact;
    } catch (e) {
      print('📞 [API ERROR] Error fetching contact by ID: $e');
      throw Exception('Failed to fetch contact by ID: $e');
    }
  }
} 