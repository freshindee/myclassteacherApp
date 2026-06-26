import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/today_class_model.dart';

abstract class TodayClassRemoteDataSource {
  Future<List<TodayClassModel>> getTodayClasses(String schoolId);
}

class TodayClassRemoteDataSourceImpl implements TodayClassRemoteDataSource {
  final FirebaseFirestore firestore;
  TodayClassRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TodayClassModel>> getTodayClasses(String schoolId) async {
    try {
      print('📚 [API REQUEST] TodayClassDataSource.getTodayClasses called with schoolId: $schoolId');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayOfWeek = _getDayOfWeek(today.weekday);
      
      print('📚 [API REQUEST] Querying for today: $today, day of week: $dayOfWeek');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('today_classes')
          .where('day', isEqualTo: dayOfWeek)
          .get();
      
      print('📚 [API RESPONSE] Found ${querySnapshot.docs.length} today class documents for schoolId: $schoolId, day: $dayOfWeek');
      
      final classes = querySnapshot.docs.map((doc) {
        final data = doc.data();
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