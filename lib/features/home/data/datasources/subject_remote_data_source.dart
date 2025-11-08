import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

abstract class SubjectRemoteDataSource {
  Future<List<SubjectModel>> getSubjects(String teacherId);
}

class SubjectRemoteDataSourceImpl implements SubjectRemoteDataSource {
  final FirebaseFirestore firestore;
  SubjectRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SubjectModel>> getSubjects(String teacherId) async {
    try {
      print('📚 [API REQUEST] SubjectDataSource.getSubjects called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('subjects')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      print('📚 [API RESPONSE] Found ${querySnapshot.docs.length} subject documents for teacherId: $teacherId');
      
      final subjects = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📚 [API RESPONSE] Subject document ${doc.id}: $data');
        return SubjectModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📚 [API RESPONSE] Successfully parsed ${subjects.length} subjects');
      return subjects;
    } catch (e) {
      print('📚 [API ERROR] Error fetching subjects: $e');
      throw Exception('Failed to fetch subjects: $e');
    }
  }
}

