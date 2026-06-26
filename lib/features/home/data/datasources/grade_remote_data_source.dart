import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';

abstract class GradeRemoteDataSource {
  Future<List<GradeModel>> getGrades(String schoolId);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final FirebaseFirestore firestore;

  GradeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<GradeModel>> getGrades(String schoolId) async {
    try {
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GradeModel(
          id: data['id'] as String? ?? doc.id,
          name: data['name'] as String? ?? '',
          teacherId: schoolId,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch grades: $e');
    }
  }
}

