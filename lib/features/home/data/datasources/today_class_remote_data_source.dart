import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/today_class_model.dart';

abstract class TodayClassRemoteDataSource {
  Future<List<TodayClassModel>> getTodayClasses();
}

class TodayClassRemoteDataSourceImpl implements TodayClassRemoteDataSource {
  final FirebaseFirestore firestore;
  TodayClassRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TodayClassModel>> getTodayClasses() async {
    try {
      final querySnapshot = await firestore.collection('today_classes').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return TodayClassModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch today classes: $e');
    }
  }
} 