import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/contact_model.dart';

abstract class ContactRemoteDataSource {
  Future<List<ContactModel>> getContacts(String teacherId);
  Future<ContactModel?> getContactById(String teacherId, String contactId);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final FirebaseFirestore firestore;

  ContactRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<ContactModel>> getContacts(String teacherId) async {
    try {
      print('📞 [API REQUEST] ContactDataSource.getContacts called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('contacts')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      print('📞 [API RESPONSE] Found ${querySnapshot.docs.length} contact documents for teacherId: $teacherId');
      
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
  Future<ContactModel?> getContactById(String teacherId, String contactId) async {
    try {
      print('📞 [API REQUEST] ContactDataSource.getContactById called with teacherId: $teacherId, contactId: $contactId');
      
      final doc = await firestore
          .collection('contacts')
          .doc(contactId)
          .get();
      
      if (!doc.exists) {
        print('📞 [API RESPONSE] Contact document not found for contactId: $contactId');
        return null;
      }
      
      final data = doc.data()!;
      print('📞 [API RESPONSE] Contact document ${doc.id}: $data');
      
      // Check if the contact belongs to the specified teacher
      if (data['teacherId'] != teacherId) {
        print('📞 [API RESPONSE] Contact does not belong to teacherId: $teacherId');
        return null;
      }
      
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