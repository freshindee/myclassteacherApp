import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<TeacherModel>> getTeachers(String schoolId);
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final FirebaseFirestore firestore;
  TeacherRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeacherModel>> getTeachers(String schoolId) async {
    try {
      print('👨‍🏫 [API REQUEST] TeacherDataSource.getTeachers called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .get();
      
      print('👨‍🏫 [API RESPONSE] Found ${querySnapshot.docs.length} teacher documents for schoolId: $schoolId');
      
      final teachers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('👨‍🏫 [API RESPONSE] Teacher document ${doc.id}: $data');
        return TeacherModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('👨‍🏫 [API RESPONSE] Successfully parsed ${teachers.length} teachers');
      return teachers;
    } catch (e) {
      print('👨‍🏫 [API ERROR] Error fetching teachers: $e');
      throw Exception('Failed to fetch teachers: $e');
    }
  }
} 