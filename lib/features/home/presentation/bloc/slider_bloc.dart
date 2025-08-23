import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/slider_image.dart';
import '../../domain/usecases/get_slider_images.dart';

// Events
abstract class SliderEvent extends Equatable {
  const SliderEvent();

  @override
  List<Object> get props => [];
}

class LoadSliderImages extends SliderEvent {
  final String teacherId;

  const LoadSliderImages(this.teacherId);

  @override
  List<Object> get props => [teacherId];
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

  SliderBloc({required this.getSliderImages}) : super(SliderInitial()) {
    on<LoadSliderImages>(_onLoadSliderImages);
  }

  Future<void> _onLoadSliderImages(
    LoadSliderImages event,
    Emitter<SliderState> emit,
  ) async {
    emit(SliderLoading());

    print('🖼️ [BLOC] SliderBloc: Loading slider images for teacherId: ${event.teacherId}');

    final result = await getSliderImages(event.teacherId);
    
    result.fold(
      (failure) {
        print('🖼️ [BLOC ERROR] Failed to load slider images: ${failure.message}');
        emit(SliderError(failure.message));
      },
      (sliderImages) {
        print('🖼️ [BLOC] Successfully loaded ${sliderImages.length} slider images');
        emit(SliderLoaded(sliderImages));
      },
    );
  }
}
