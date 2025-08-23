import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/slider_image.dart';

abstract class SliderRepository {
  Future<Either<Failure, List<SliderImage>>> getSliderImages(String teacherId);
}
