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
      
      // Log displayId list before sorting
      developer.log('displayId list before sorting: ' + timetables.map((t) => t.displayId).toList().toString(), name: 'TimetableDataSource');
      // Sort by displayId (nulls last)
      timetables.sort((a, b) {
        if (a.displayId == null && b.displayId == null) return 0;
        if (a.displayId == null) return 1;
        if (b.displayId == null) return -1;
        return a.displayId!.compareTo(b.displayId!);
      });
      // Log displayId list after sorting
      developer.log('displayId list after sorting: ' + timetables.map((t) => t.displayId).toList().toString(), name: 'TimetableDataSource');
      
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

      // Map to store the minimum index for each grade
      final Map<String, int> gradeToMinIndex = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final grade = data['grade'] as String?;
        final indexRaw = data['index'];
        final index = indexRaw is int ? indexRaw : int.tryParse(indexRaw?.toString() ?? '');
        if (grade != null && index != null) {
          if (!gradeToMinIndex.containsKey(grade) || index < gradeToMinIndex[grade]!) {
            gradeToMinIndex[grade] = index;
          }
        }
      }

      // Sort grades by their minimum index
      final grades = gradeToMinIndex.keys.toList()
        ..sort((a, b) => gradeToMinIndex[a]!.compareTo(gradeToMinIndex[b]!));

      developer.log('✅ Found [32m${grades.length}[0m available grades (sorted by index): $grades', name: 'TimetableDataSource');
      return grades;
    } catch (e) {
      developer.log('❌ Error fetching available grades: $e', name: 'TimetableDataSource');
      throw Exception('Failed to fetch available grades: $e');
    }
  }
} 