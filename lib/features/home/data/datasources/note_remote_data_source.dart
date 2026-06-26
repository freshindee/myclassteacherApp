import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes(String schoolId);
  Future<List<NoteModel>> getNotesByGrade(String schoolId, String grade);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final FirebaseFirestore firestore;

  NoteRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<NoteModel>> getNotes(String schoolId) async {
    try {
      print('📝 [API REQUEST] NoteDataSource.getNotes called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('notes')
          .get();
      
      print('📝 [API RESPONSE] Found ${querySnapshot.docs.length} note documents for schoolId: $schoolId');
      
      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📝 [API RESPONSE] Note document ${doc.id}: $data');
        return NoteModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📝 [API RESPONSE] Successfully parsed ${notes.length} notes');
      return notes;
    } catch (e) {
      print('📝 [API ERROR] Error fetching notes: $e');
      throw Exception('Failed to fetch notes: $e');
    }
  }

  @override
  Future<List<NoteModel>> getNotesByGrade(String schoolId, String grade) async {
    try {
      print('📝 [API REQUEST] NoteDataSource.getNotesByGrade called with schoolId: $schoolId, grade: $grade');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('notes')
          .where('grade', isEqualTo: grade)
          .get();
      
      print('📝 [API RESPONSE] Found ${querySnapshot.docs.length} note documents for schoolId: $schoolId, grade: $grade');
      
      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📝 [API RESPONSE] Note document ${doc.id}: $data');
        return NoteModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📝 [API RESPONSE] Successfully parsed ${notes.length} notes for grade $grade');
      return notes;
    } catch (e) {
      print('📝 [API ERROR] Error fetching notes by grade: $e');
      throw Exception('Failed to fetch notes by grade: $e');
    }
  }
} 