import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/exam_chapter_model.dart';

abstract class ExamChapterRemoteDataSource {
  Future<List<ExamChapterModel>> getExamChapters(String subjectId);
}

class ExamChapterRemoteDataSourceImpl implements ExamChapterRemoteDataSource {
  final ApiClient apiClient;

  ExamChapterRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ExamChapterModel>> getExamChapters(String subjectId) async {
    try {
      print('📝 [API REQUEST] ExamChapterDataSource.getExamChapters called with subject_id: $subjectId');

      final response = await apiClient.get(
        ApiEndpoints.papersChapters,
        queryParameters: {'subject_id': subjectId},
      );

      if (!response.isSuccess) {
        print('📝 [API ERROR] Failed to fetch exam chapters: ${response.error}');
        throw Exception(response.error ?? 'Failed to fetch exam chapters');
      }

      final data = response.data;
      if (data == null) {
        print('📝 [API ERROR] Response data is null');
        throw Exception('No data received from API');
      }

      // Parse the response structure: {"records": [...]} or direct array
      List<dynamic> records;
      if (data is Map<String, dynamic>) {
        records = data['records'] as List<dynamic>? ?? [];
      } else if (data is List) {
        records = data;
      } else {
        print('📝 [API ERROR] Unexpected response format: ${data.runtimeType}');
        throw Exception('Unexpected response format from API');
      }

      final chapters = records.map((record) {
        return ExamChapterModel.fromJson(record as Map<String, dynamic>);
      }).toList();

      print('📝 [API RESPONSE] Successfully parsed ${chapters.length} exam chapters');
      return chapters;
    } catch (e) {
      print('📝 [API ERROR] Error fetching exam chapters: $e');
      throw Exception('Failed to fetch exam chapters: $e');
    }
  }
}
