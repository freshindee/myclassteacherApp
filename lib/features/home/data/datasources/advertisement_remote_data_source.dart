import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

abstract class AdvertisementRemoteDataSource {
  Future<List<VideoModel>> getAdvertisements(String schoolId);
}

class AdvertisementRemoteDataSourceImpl implements AdvertisementRemoteDataSource {
  final FirebaseFirestore firestore;

  AdvertisementRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<VideoModel>> getAdvertisements(String schoolId) async {
    try {
      print('📢 [API REQUEST] AdvertisementDataSource.getAdvertisements called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('advertisements')
          .get();
      
      print('📢 [API RESPONSE] Found ${querySnapshot.docs.length} advertisement documents for schoolId: $schoolId');
      
      final advertisements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('📢 [API RESPONSE] Advertisement document ${doc.id}: $data');
        return VideoModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('📢 [API RESPONSE] Successfully parsed ${advertisements.length} advertisements');
      return advertisements;
    } catch (e) {
      print('📢 [API ERROR] Error fetching advertisements: $e');
      throw Exception('Failed to fetch advertisements: $e');
    }
  }
} 