import 'package:equatable/equatable.dart';

class SliderImage extends Equatable {
  final String id;
  final String teacherId;
  final String imageUrl;

  const SliderImage({
    required this.id,
    required this.teacherId,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, teacherId, imageUrl];
}
