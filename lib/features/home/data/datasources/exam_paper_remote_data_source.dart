import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/exam_paper_model.dart';

abstract class ExamPaperRemoteDataSource {
  Future<List<ExamPaperModel>> getExamPapers({
    required String grade,
    required int subjectId,
    int? chapterId,
  });
}

class ExamPaperRemoteDataSourceImpl implements ExamPaperRemoteDataSource {
  final ApiClient apiClient;

  ExamPaperRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ExamPaperModel>> getExamPapers({
    required String grade,
    required int subjectId,
    int? chapterId,
  }) async {
    try {
      print('📝 [API REQUEST] ExamPaperDataSource.getExamPapers called');
      print('📝 [API REQUEST] - grade: $grade, subjectId: $subjectId, chapterId: $chapterId');
      
      // Build query parameters
      final queryParameters = <String, dynamic>{
        'grade': grade,
        'subject_id': subjectId,
      };
      
      // Add chapter_id only if provided
      if (chapterId != null && chapterId > 0) {
        queryParameters['chapter_id'] = chapterId;
      }
      
      final response = await apiClient.get(
        ApiEndpoints.papersList,
        queryParameters: queryParameters,
      );

      if (!response.isSuccess) {
        print('📝 [API ERROR] Failed to fetch exam papers: ${response.error}');
        throw Exception(response.error ?? 'Failed to fetch exam papers');
      }

      final data = response.data;
      if (data == null) {
        print('📝 [API ERROR] Response data is null');
        throw Exception('No data received from API');
      }

      // Parse the response structure: {"records": [...]}
      List<dynamic> records;
      if (data is Map<String, dynamic>) {
        records = data['records'] as List<dynamic>? ?? [];
      } else if (data is List) {
        records = data;
      } else {
        print('📝 [API ERROR] Unexpected response format: ${data.runtimeType}');
        throw Exception('Unexpected response format from API');
      }

      final papers = records.map((record) {
        return ExamPaperModel.fromJson(record as Map<String, dynamic>);
      }).toList();

      print('📝 [API RESPONSE] Successfully parsed ${papers.length} exam papers');
      return papers;
    } catch (e) {
      print('📝 [API ERROR] Error fetching exam papers: $e');
      throw Exception('Failed to fetch exam papers: $e');
    }
  }
}
