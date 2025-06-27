part of 'free_classes_page.dart';

class FreeClassesBloc extends Bloc<FreeClassesEvent, FreeClassesState> {
  final GetAdvertisements getAdvertisements;

  FreeClassesBloc({required this.getAdvertisements}) : super(FreeClassesInitial()) {
    on<LoadFreeVideos>(_onLoadFreeVideos);
  }

  Future<void> _onLoadFreeVideos(
    LoadFreeVideos event,
    Emitter<FreeClassesState> emit,
  ) async {
    emit(FreeClassesLoading());
    developer.log('🔄 Loading advertisements...', name: 'FreeClassesBloc');
    final result = await getAdvertisements(NoParams());
    result.fold(
      (failure) {
        final errorMessage = failure is ServerFailure
            ? failure.message
            : 'An unexpected error occurred';
        developer.log('❌ Failed to load advertisements: $errorMessage',
            name: 'FreeClassesBloc');
        emit(FreeClassesError(errorMessage));
      },
      (advertisements) {
        developer.log('✅ Loaded ${advertisements.length} advertisements successfully',
            name: 'FreeClassesBloc');
        emit(FreeClassesLoaded(advertisements));
      },
    );
  }
} 