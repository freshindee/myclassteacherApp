import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/timetable_model.dart';

abstract class TimetableRemoteDataSource {
  Future<List<TimetableModel>> getTimetableByGrade(String grade);
  Future<List<String>> getAvailableGrades();
}

class TimetableRemoteDataSourceImpl implements TimetableRemoteDataSource {
  final FirebaseFirestore firestore;

  TimetableRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<TimetableModel>> getTimetableByGrade(String grade) async {
    try {
      developer.log('🔍 Fetching timetable for grade $grade from Firestore...', name: 'TimetableDataSource');
      
      final querySnapshot = await firestore.collection('timetable').where('grade', isEqualTo: grade).get();
      
      developer.log('📊 Found ${querySnapshot.docs.length} timetable documents for grade $grade', name: 'TimetableDataSource');
      
      final timetables = querySnapshot.docs.map((doc) {
        final data = doc.data();
        developer.log('📅 Timetable document ${doc.id}: $data', name: 'TimetableDataSource');
        
        return TimetableModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      developer.log('✅ Successfully parsed ${timetables.length} timetable entries', name: 'TimetableDataSource');
      return timetables;
    } catch (e) {
      developer.log('❌ Error fetching timetable for grade $grade: $e', name: 'TimetableDataSource');
      throw Exception('Failed to fetch timetable for grade $grade: $e');
    }
  }

  @override
  Future<List<String>> getAvailableGrades() async {
    try {
      developer.log('🔍 Fetching available grades from Firestore...', name: 'TimetableDataSource');
      
      final querySnapshot = await firestore.collection('timetable').get();
      
      final grades = querySnapshot.docs
          .map((doc) => doc.data()['grade'] as String?)
          .where((grade) => grade != null)
          .map((grade) => grade!)
          .toSet()
          .toList()
        ..sort((a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? a.compareTo(b));
      
      developer.log('✅ Found ${grades.length} available grades: $grades', name: 'TimetableDataSource');
      return grades;
    } catch (e) {
      developer.log('❌ Error fetching available grades: $e', name: 'TimetableDataSource');
      throw Exception('Failed to fetch available grades: $e');
    }
  }
} 