import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<TeacherModel>> getTeachers();
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final FirebaseFirestore firestore;
  TeacherRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeacherModel>> getTeachers() async {
    try {
      final querySnapshot = await firestore.collection('teachers').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return TeacherModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }
} 