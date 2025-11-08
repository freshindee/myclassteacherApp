import '../../domain/entities/slider_image.dart';

class SliderImageModel extends SliderImage {
  const SliderImageModel({
    required super.id,
    required super.teacherId,
    required super.imageUrl,
  });

  factory SliderImageModel.fromJson(Map<String, dynamic> json) {
    // Try to get image from different possible field names
    String? imageUrl;
    
    // Check for image1, image2, image3 fields first
    if (json['image1'] != null && json['image1'].toString().isNotEmpty) {
      imageUrl = json['image1'].toString();
    } else if (json['image2'] != null && json['image2'].toString().isNotEmpty) {
      imageUrl = json['image2'].toString();
    } else if (json['image3'] != null && json['image3'].toString().isNotEmpty) {
      imageUrl = json['image3'].toString();
    } else if (json['image4'] != null && json['image4'].toString().isNotEmpty) {
      imageUrl = json['image4'].toString();
    }
    
    // If no valid image URL found, use a placeholder
    imageUrl ??= 'https://via.placeholder.com/400x200?text=No+Image';
    
    return SliderImageModel(
      id: json['id'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'image': imageUrl,
    };
  }

  SliderImage toEntity() {
    return SliderImage(
      id: id,
      teacherId: teacherId,
      imageUrl: imageUrl,
    );
  }
}
