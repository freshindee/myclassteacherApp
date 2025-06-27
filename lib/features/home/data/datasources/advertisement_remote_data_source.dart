import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

abstract class AdvertisementRemoteDataSource {
  Future<List<VideoModel>> getAdvertisements();
}

class AdvertisementRemoteDataSourceImpl implements AdvertisementRemoteDataSource {
  final FirebaseFirestore firestore;

  AdvertisementRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<VideoModel>> getAdvertisements() async {
    try {
      final QuerySnapshot snapshot = await firestore
          .collection('advertiesments')
          .get();

      return snapshot.docs
          .map((doc) => VideoModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch advertisements: $e');
    }
  }
} 