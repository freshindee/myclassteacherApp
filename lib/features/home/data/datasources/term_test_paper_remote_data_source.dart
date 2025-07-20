import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/term_test_paper_model.dart';

abstract class TermTestPaperRemoteDataSource {
  Future<List<TermTestPaperModel>> getTermTestPapers({String? grade, String? subject, int? term});
}

class TermTestPaperRemoteDataSourceImpl implements TermTestPaperRemoteDataSource {
  final FirebaseFirestore firestore;

  TermTestPaperRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TermTestPaperModel>> getTermTestPapers({String? grade, String? subject, int? term}) async {
    print('[TermTestPaperRemoteDataSource] Fetching with params: grade=$grade, subject=$subject, term=$term');
    // Query query = firestore.collection('term_test_papers');
    // if (grade != null && grade.isNotEmpty) {
    //   query = query.where('grade', isEqualTo: grade);
    // }
    // if (subject != null && subject.isNotEmpty) {
    //   query = query.where('subject', isEqualTo: subject);
    // }
    // if (term != null) {
    //   query = query.where('term', isEqualTo: term.toString());
    // }
    // All parameters are required, so no null checks needed in the query
    final snapshot = await firestore
        .collection('term_test_papers')
        .where('grade', isEqualTo: grade)
        .where('subject', isEqualTo: subject)
        .where('term', isEqualTo: term.toString())
        .get();
    return snapshot.docs.map((doc) => TermTestPaperModel.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }
} 