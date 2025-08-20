import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/timetable_model.dart';

abstract class TimetableRemoteDataSource {
  Future<List<TimetableModel>> getTimetableByGrade(String teacherId, String grade);
  Future<List<String>> getAvailableGrades(String teacherId);
}

class TimetableRemoteDataSourceImpl implements TimetableRemoteDataSource {
  final FirebaseFirestore firestore;

  TimetableRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<TimetableModel>> getTimetableByGrade(String teacherId, String grade) async {
    try {
      print('📅 [API REQUEST] TimetableDataSource.getTimetableByGrade called with teacherId: $teacherId, grade: $grade');
      
      final querySnapshot = await firestore
          .collection('timetable')
          .where('teacherId', isEqualTo: teacherId)
          .where('grade', isEqualTo: grade)
          .get();
      
      print('📅 [API RESPONSE] Found ${querySnapshot.docs.length} timetable documents for teacherId: $teacherId, grade: $grade');
      
      final timetables = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📅 [API RESPONSE] Timetable document ${doc.id}: $data');
        return TimetableModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📅 [API RESPONSE] Successfully parsed ${timetables.length} timetables for grade $grade');
      return timetables;
    } catch (e) {
      print('📅 [API ERROR] Error fetching timetable by grade: $e');
      throw Exception('Failed to fetch timetable by grade: $e');
    }
  }

  @override
  Future<List<String>> getAvailableGrades(String teacherId) async {
    try {
      print('📅 [API REQUEST] TimetableDataSource.getAvailableGrades called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('timetable')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      print('📅 [API RESPONSE] Found ${querySnapshot.docs.length} timetable documents for teacherId: $teacherId');
      
      final grades = querySnapshot.docs
          .map((doc) => doc.data()['grade'] as String)
          .where((grade) => grade != null && grade.isNotEmpty)
          .toSet()
          .toList();
      
      print('📅 [API RESPONSE] Successfully extracted ${grades.length} unique grades: $grades');
      return grades;
    } catch (e) {
      print('📅 [API ERROR] Error fetching available grades: $e');
      throw Exception('Failed to fetch available grades: $e');
    }
  }
} 