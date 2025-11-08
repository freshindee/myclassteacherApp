import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';

abstract class GradeRemoteDataSource {
  Future<List<GradeModel>> getGrades(String teacherId);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final FirebaseFirestore firestore;

  GradeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<GradeModel>> getGrades(String teacherId) async {
    try {
      final querySnapshot = await firestore
          .collection('grades')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      return querySnapshot.docs.map((doc) => GradeModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch grades: $e');
    }
  }
}

