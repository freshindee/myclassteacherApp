import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/contact_model.dart';

abstract class ContactRemoteDataSource {
  Future<List<ContactModel>> getContacts();
  Future<ContactModel> getContactById(String id);
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final FirebaseFirestore firestore;

  ContactRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<ContactModel>> getContacts() async {
    try {
      developer.log('🔍 Fetching contacts from Firestore...', name: 'ContactDataSource');
      
      final querySnapshot = await firestore.collection('contacts').get();
      
      developer.log('📊 Found ${querySnapshot.docs.length} contact documents', name: 'ContactDataSource');
      
      final contacts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        developer.log('📞 Contact document ${doc.id}: $data', name: 'ContactDataSource');
        
        return ContactModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      developer.log('✅ Successfully parsed ${contacts.length} contacts', name: 'ContactDataSource');
      return contacts;
    } catch (e) {
      developer.log('❌ Error fetching contacts: $e', name: 'ContactDataSource');
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  @override
  Future<ContactModel> getContactById(String id) async {
    try {
      developer.log('🔍 Fetching contact by ID: $id', name: 'ContactDataSource');
      
      final docSnapshot = await firestore.collection('contacts').doc(id).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Contact not found');
      }
      
      final data = docSnapshot.data()!;
      developer.log('📞 Contact document $id: $data', name: 'ContactDataSource');
      
      final contact = ContactModel.fromJson({
        'id': docSnapshot.id,
        ...data,
      });
      
      developer.log('✅ Successfully parsed contact: ${contact.name}', name: 'ContactDataSource');
      return contact;
    } catch (e) {
      developer.log('❌ Error fetching contact by ID: $e', name: 'ContactDataSource');
      throw Exception('Failed to fetch contact: $e');
    }
  }
} 