import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/slider_image_model.dart';

abstract class SliderRemoteDataSource {
  Future<List<SliderImageModel>> getSliderImages(String schoolId);
}

class SliderRemoteDataSourceImpl implements SliderRemoteDataSource {
  final FirebaseFirestore firestore;

  SliderRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SliderImageModel>> getSliderImages(String schoolId) async {
    try {
      print('🖼️ [API REQUEST] SliderDataSource.getSliderImages called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('slider')
          .get();
      
      print('🖼️ [API RESPONSE] Found ${querySnapshot.docs.length} slider documents for schoolId: $schoolId');
      
      final List<SliderImageModel> sliderImages = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print('🖼️ [API RESPONSE] Slider document ${doc.id}: $data');
        
        final imageFields = ['image1', 'image2', 'image3', 'image4'];
        int imageIndex = 1;
        
        for (final field in imageFields) {
          if (data[field] != null && data[field].toString().isNotEmpty) {
            final sliderImage = SliderImageModel.fromJson({
              'id': '${doc.id}_$imageIndex',
              'teacherId': schoolId,
              field: data[field],
            });
            sliderImages.add(sliderImage);
            imageIndex++;
          }
        }
      }
      
      print('🖼️ [API RESPONSE] Successfully parsed ${sliderImages.length} slider images');
      return sliderImages;
    } catch (e) {
      print('🖼️ [API ERROR] Error fetching slider images: $e');
      throw Exception('Failed to fetch slider images: $e');
    }
  }
}
