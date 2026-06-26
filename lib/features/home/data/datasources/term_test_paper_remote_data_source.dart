import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/term_test_paper_model.dart';

abstract class TermTestPaperRemoteDataSource {
  Future<List<TermTestPaperModel>> getTermTestPapers({required String schoolId, String? grade, String? subject, int? term});
}

class TermTestPaperRemoteDataSourceImpl implements TermTestPaperRemoteDataSource {
  final FirebaseFirestore firestore;

  TermTestPaperRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TermTestPaperModel>> getTermTestPapers({
    required String schoolId,
    String? grade,
    String? subject,
    int? term,
  }) async {
    try {
      print('📄 [API REQUEST] TermTestPaperDataSource.getTermTestPapers called with:');
      print('📄   - schoolId: $schoolId');
      print('📄   - grade: $grade');
      print('📄   - subject: $subject');
      print('📄   - term: $term');
      
      Query<Map<String, dynamic>> query = firestore
          .collection('schools')
          .doc(schoolId)
          .collection('term_test_papers');
      
      // Apply filters
      
      if (grade != null && grade.isNotEmpty) {
        query = query.where('grade', isEqualTo: grade);
        print('📄 [API REQUEST] Applied filter: grade = $grade');
      }
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
        print('📄 [API REQUEST] Applied filter: subject = $subject');
      }
      if (term != null) {
        query = query.where('term', isEqualTo: term);
        print('📄 [API REQUEST] Applied filter: term = $term');
      }
      
      print('📄 [API REQUEST] Executing Firestore query...');
      final querySnapshot = await query.get();
      
      print('📄 [API RESPONSE] Found ${querySnapshot.docs.length} term test paper documents');
      
      final papers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📄 [API RESPONSE] Term test paper document ${doc.id}: $data');
        return TermTestPaperModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📄 [API RESPONSE] Successfully parsed ${papers.length} term test papers');
      return papers;
    } catch (e) {
      print('📄 [API ERROR] Error fetching term test papers: $e');
      throw Exception('Failed to fetch term test papers: $e');
    }
  }
} 