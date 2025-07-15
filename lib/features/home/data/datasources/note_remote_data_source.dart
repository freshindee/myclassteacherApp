import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes();
  Future<List<NoteModel>> getNotesByGrade(String grade);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final FirebaseFirestore firestore;

  NoteRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<NoteModel>> getNotes() async {
    final querySnapshot = await firestore.collection('notes').get();
    return querySnapshot.docs.map((doc) {
      return NoteModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }

  @override
  Future<List<NoteModel>> getNotesByGrade(String grade) async {
    final querySnapshot = await firestore.collection('notes').where('grade', isEqualTo: grade).get();
    return querySnapshot.docs.map((doc) {
      return NoteModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }
} 