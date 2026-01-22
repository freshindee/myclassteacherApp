import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/exam_subject_model.dart';

abstract class ExamSubjectRemoteDataSource {
  Future<List<ExamSubjectModel>> getExamSubjects();
}

class ExamSubjectRemoteDataSourceImpl implements ExamSubjectRemoteDataSource {
  final ApiClient apiClient;

  ExamSubjectRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ExamSubjectModel>> getExamSubjects() async {
    try {
      print('📝 [API REQUEST] ExamSubjectDataSource.getExamSubjects called');
      
      final response = await apiClient.get(
        ApiEndpoints.papersSubjects,
      );

      if (!response.isSuccess) {
        print('📝 [API ERROR] Failed to fetch exam subjects: ${response.error}');
        throw Exception(response.error ?? 'Failed to fetch exam subjects');
      }

      final data = response.data;
      if (data == null) {
        print('📝 [API ERROR] Response data is null');
        throw Exception('No data received from API');
      }

      // Parse the response structure: {"records": [...]}
      if (data is Map<String, dynamic>) {
        final records = data['records'] as List<dynamic>?;
        if (records == null) {
          print('📝 [API ERROR] No records found in response');
          throw Exception('No records found in API response');
        }

        final subjects = records.map((record) {
          return ExamSubjectModel.fromJson(record as Map<String, dynamic>);
        }).toList();

        print('📝 [API RESPONSE] Successfully parsed ${subjects.length} exam subjects');
        return subjects;
      } else {
        print('📝 [API ERROR] Unexpected response format: ${data.runtimeType}');
        throw Exception('Unexpected response format from API');
      }
    } catch (e) {
      print('📝 [API ERROR] Error fetching exam subjects: $e');
      throw Exception('Failed to fetch exam subjects: $e');
    }
  }
}
