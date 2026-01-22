import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes(String teacherId);
  Future<List<NoteModel>> getNotesByGrade(String teacherId, String grade);
  Future<List<NoteModel>> getFreeNotes(String teacherId, {String? grade});
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final FirebaseFirestore firestore;

  NoteRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<NoteModel>> getNotes(String teacherId) async {
    try {
      print('📝 [API REQUEST] NoteDataSource.getNotes called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('notes')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      print('📝 [API RESPONSE] Found ${querySnapshot.docs.length} note documents for teacherId: $teacherId');
      
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
  Future<List<NoteModel>> getNotesByGrade(String teacherId, String grade) async {
    try {
      print('📝 [API REQUEST] NoteDataSource.getNotesByGrade called with teacherId: $teacherId, grade: $grade');
      
      final querySnapshot = await firestore
          .collection('notes')
          .where('teacherId', isEqualTo: teacherId)
          .where('grade', isEqualTo: grade)
          .get();
      
      print('📝 [API RESPONSE] Found ${querySnapshot.docs.length} note documents for teacherId: $teacherId, grade: $grade');
      
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

  @override
  Future<List<NoteModel>> getFreeNotes(String teacherId, {String? grade}) async {
    try {
      print('📝 [API REQUEST] NoteDataSource.getFreeNotes called with teacherId: $teacherId (type: ${teacherId.runtimeType}), grade: $grade');
      
      // Use teacherId as string (database stores it as string "100103")
      Query query = firestore
          .collection('notes')
          .where('teacherId', isEqualTo: teacherId)
          .where('accessLevel', isEqualTo: 'free');
      
      // Add grade filter if provided
      if (grade != null && grade.isNotEmpty) {
        query = query.where('grade', isEqualTo: grade);
        print('📝 [API REQUEST] Filtering by grade: $grade');
      }
      
      print('📝 [API REQUEST] Executing query: teacherId="$teacherId", accessLevel="free", grade="$grade"');
      final querySnapshot = await query.get();
      
      print('📝 [API RESPONSE] Found ${querySnapshot.docs.length} free note documents for teacherId: $teacherId');
      
      final notes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('📝 [API RESPONSE] Free note document ${doc.id}: $data');
        return NoteModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📝 [API RESPONSE] Successfully parsed ${notes.length} free notes');
      return notes;
    } catch (e) {
      print('📝 [API ERROR] Error fetching free notes: $e');
      throw Exception('Failed to fetch free notes: $e');
    }
  }
} 