import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/slider_image.dart';
import '../repositories/slider_repository.dart';

class GetSliderImages implements UseCase<List<SliderImage>, String> {
  final SliderRepository repository;

  GetSliderImages(this.repository);

  @override
  Future<Either<Failure, List<SliderImage>>> call(String teacherId) async {
    return await repository.getSliderImages(teacherId);
  }
}
