import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/today_class_model.dart';

abstract class TodayClassRemoteDataSource {
  Future<List<TodayClassModel>> getTodayClasses(String teacherId, {String? grade, String? subject});
}

class TodayClassRemoteDataSourceImpl implements TodayClassRemoteDataSource {
  final FirebaseFirestore firestore;
  TodayClassRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TodayClassModel>> getTodayClasses(String teacherId, {String? grade, String? subject}) async {
    try {
      print('📚 [API REQUEST] TodayClassDataSource.getTodayClasses called with teacherId: $teacherId, grade: $grade, subject: $subject');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayOfWeek = _getDayOfWeek(today.weekday);
      
      print('📚 [API REQUEST] Querying for today: $today, day of week: $dayOfWeek');
      
      Query query = firestore
          .collection('today_classes')
          .where('teacherId', isEqualTo: teacherId)
          .where('day', isEqualTo: dayOfWeek);
      
      // Add grade filter if provided
      if (grade != null && grade.isNotEmpty) {
        query = query.where('grade', isEqualTo: grade);
        print('📚 [API REQUEST] Filtering by grade: $grade');
      }
      
      // Add subject filter if provided
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
        print('📚 [API REQUEST] Filtering by subject: $subject');
      }
      
      final querySnapshot = await query.get();
      
      print('📚 [API RESPONSE] Found ${querySnapshot.docs.length} today class documents for teacherId: $teacherId, day: $dayOfWeek');
      
      final classes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('📚 [API RESPONSE] Today class document ${doc.id}:');
        print('📚 [API RESPONSE] Raw data keys: ${data.keys.toList()}');
        print('📚 [API RESPONSE] zoomId value: ${data['zoomId']} (type: ${data['zoomId']?.runtimeType})');
        print('📚 [API RESPONSE] password value: ${data['password']} (type: ${data['password']?.runtimeType})');
        print('📚 [API RESPONSE] Full data: $data');
        return TodayClassModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📚 [API RESPONSE] Successfully parsed ${classes.length} today classes');
      return classes;
    } catch (e) {
      print('📚 [API ERROR] Error fetching today classes: $e');
      throw Exception('Failed to fetch today classes: $e');
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
} 