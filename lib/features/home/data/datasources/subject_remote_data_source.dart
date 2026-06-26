import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

abstract class SubjectRemoteDataSource {
  Future<List<SubjectModel>> getSubjects(String schoolId);
}

class SubjectRemoteDataSourceImpl implements SubjectRemoteDataSource {
  final FirebaseFirestore firestore;
  SubjectRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SubjectModel>> getSubjects(String schoolId) async {
    try {
      print('📚 [API REQUEST] SubjectDataSource.getSubjects called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('subjects')
          .get();
      
      print('📚 [API RESPONSE] Found ${querySnapshot.docs.length} subject documents for schoolId: $schoolId');
      
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

