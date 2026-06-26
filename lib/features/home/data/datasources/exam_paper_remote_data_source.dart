import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/exam_paper_model.dart';

abstract class ExamPaperRemoteDataSource {
  Future<List<ExamPaperModel>> getExamPapers({
    required String grade,
    required int subjectId,
    int? chapterId,
    String? subjectIdStr,
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
    String? subjectIdStr,
  }) async {
    try {
      print('📝 [API REQUEST] ExamPaperDataSource.getExamPapers called');
      print('📝 [API REQUEST] - grade: $grade, subjectId: $subjectId, subjectIdStr: $subjectIdStr, chapterId: $chapterId');

      // Paper table uses string subject_id (e.g. class_subject id). Prefer subjectIdStr when set.
      final queryParameters = <String, dynamic>{
        'grade': grade,
        'subject_id': subjectIdStr != null && subjectIdStr.isNotEmpty ? subjectIdStr : subjectId,
      };

      if (chapterId != null && chapterId > 0) {
        queryParameters['chapter_id'] = chapterId;
      }
      
      final response = await apiClient.get(
        ApiEndpoints.papersList,
        queryParameters: queryParameters,
      );

      // Treat 404 "No papers found" as empty list (no error)
      if (response.statusCode == 404) {
        final msg = (response.error ?? response.data?.toString() ?? '').toString().toLowerCase();
        if (msg.contains('no papers found') || msg.isEmpty) {
          print('📝 [API RESPONSE] No papers found (404) - returning empty list');
          return [];
        }
      }

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
