import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/exam_question_model.dart';

abstract class ExamQuestionRemoteDataSource {
  Future<List<ExamQuestionModel>> getExamQuestions(int paperId);
}

class ExamQuestionRemoteDataSourceImpl implements ExamQuestionRemoteDataSource {
  final ApiClient apiClient;

  ExamQuestionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ExamQuestionModel>> getExamQuestions(int paperId) async {
    try {
      print('📝 [API REQUEST] ExamQuestionDataSource.getExamQuestions called with paperId: $paperId');
      
      final response = await apiClient.get(
        ApiEndpoints.papersQuestions,
        queryParameters: {'paper_id': paperId},
      );

      if (!response.isSuccess) {
        print('📝 [API ERROR] Failed to fetch exam questions: ${response.error}');
        throw Exception(response.error ?? 'Failed to fetch exam questions');
      }

      final data = response.data;
      if (data == null) {
        print('📝 [API ERROR] Response data is null');
        throw Exception('No data received from API');
      }

      // Handle String response - try to parse it as JSON
      dynamic jsonData = data;
      if (data is String) {
        print('📝 [API WARNING] Response is a String, attempting to parse as JSON');
        print('📝 [API RESPONSE STRING] $data');
        try {
          jsonData = json.decode(data);
          print('📝 [API] Successfully parsed String to JSON');
        } catch (e) {
          print('📝 [API ERROR] Failed to parse String as JSON: $e');
          throw Exception('API returned non-JSON response: $data');
        }
      }

      // Parse the response structure: {"records": [...]} or direct array
      List<dynamic> records;
      if (jsonData is Map<String, dynamic>) {
        records = jsonData['records'] as List<dynamic>? ?? [];
      } else if (jsonData is List) {
        records = jsonData;
      } else {
        print('📝 [API ERROR] Unexpected response format: ${jsonData.runtimeType}');
        print('📝 [API ERROR] Response data: $jsonData');
        throw Exception('Unexpected response format from API: Expected Map or List, got ${jsonData.runtimeType}');
      }

      final questions = records.map((record) {
        return ExamQuestionModel.fromJson(record as Map<String, dynamic>);
      }).toList();

      print('📝 [API RESPONSE] Successfully parsed ${questions.length} exam questions');
      return questions;
    } catch (e) {
      print('📝 [API ERROR] Error fetching exam questions: $e');
      throw Exception('Failed to fetch exam questions: $e');
    }
  }
}
