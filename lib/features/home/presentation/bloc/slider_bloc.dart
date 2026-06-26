import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/slider_image.dart';
import '../../domain/usecases/get_slider_images.dart';
import '../../../../core/services/master_data_service.dart';
import '../../../../core/services/school_cache_service.dart';

// Events
abstract class SliderEvent extends Equatable {
  const SliderEvent();

  @override
  List<Object> get props => [];
}

class LoadSliderImages extends SliderEvent {
  final String schoolId;

  const LoadSliderImages(this.schoolId);

  @override
  List<Object> get props => [schoolId];
}

// States
abstract class SliderState extends Equatable {
  const SliderState();

  @override
  List<Object> get props => [];
}

class SliderInitial extends SliderState {}

class SliderLoading extends SliderState {}

class SliderLoaded extends SliderState {
  final List<SliderImage> sliderImages;

  const SliderLoaded(this.sliderImages);

  @override
  List<Object> get props => [sliderImages];
}

class SliderError extends SliderState {
  final String message;

  const SliderError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class SliderBloc extends Bloc<SliderEvent, SliderState> {
  final GetSliderImages getSliderImages;
  final SchoolCacheService schoolCacheService;

  SliderBloc({
    required this.getSliderImages,
    required this.schoolCacheService,
  }) : super(SliderInitial()) {
    on<LoadSliderImages>(_onLoadSliderImages);
  }

  Future<void> _onLoadSliderImages(
    LoadSliderImages event,
    Emitter<SliderState> emit,
  ) async {
    emit(SliderLoading());

    final schoolId = event.schoolId;
    print('🖼️ [BLOC] SliderBloc: Loading slider images for schoolId: $schoolId');

    try {
      // 1. Students: try cached app_config (sliderImages) from SQLite first
      final appConfig = await schoolCacheService.getAppConfigSingle(schoolId);
      if (appConfig != null && appConfig.sliderImages.isNotEmpty) {
        final sliderImages = appConfig.sliderImages.asMap().entries.map((entry) {
          final index = entry.key;
          final imageUrl = entry.value;
          return SliderImage(
            id: 'app_config_${schoolId}_$index',
            teacherId: schoolId,
            imageUrl: imageUrl,
          );
        }).toList();
        print('🖼️ [BLOC] Loaded ${sliderImages.length} slider images from app_config cache');
        emit(SliderLoaded(sliderImages));
        return;
      }

      // 2. Teachers: locally cached master data
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.sliderImages.isNotEmpty) {
        final sliderImages = masterData.sliderImages.asMap().entries.map((entry) {
          final index = entry.key;
          final imageUrl = entry.value;
          return SliderImage(
            id: 'master_${schoolId}_$index',
            teacherId: schoolId,
            imageUrl: imageUrl,
          );
        }).toList();
        print('🖼️ [BLOC] Loaded ${sliderImages.length} slider images from master data');
        emit(SliderLoaded(sliderImages));
        return;
      }

      // 3. Fallback: remote
      print('🖼️ [BLOC] No slider in cache, falling back to database');
      final result = await getSliderImages(schoolId);
      result.fold(
        (failure) {
          print('🖼️ [BLOC ERROR] Failed to load slider images: ${failure.message}');
          emit(SliderError(failure.message));
        },
        (sliderImages) {
          print('🖼️ [BLOC] Loaded ${sliderImages.length} slider images from database');
          emit(SliderLoaded(sliderImages));
        },
      );
    } catch (e) {
      print('🖼️ [BLOC ERROR] Error loading slider images: $e');
      final result = await getSliderImages(schoolId);
      result.fold(
        (failure) => emit(SliderError(failure.message)),
        (sliderImages) => emit(SliderLoaded(sliderImages)),
      );
    }
  }
}
