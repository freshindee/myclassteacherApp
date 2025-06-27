part of 'free_classes_page.dart';

abstract class FreeClassesState extends Equatable {
  const FreeClassesState();

  @override
  List<Object> get props => [];
}

class FreeClassesInitial extends FreeClassesState {}

class FreeClassesLoading extends FreeClassesState {}

class FreeClassesLoaded extends FreeClassesState {
  final List<Video> videos;

  const FreeClassesLoaded(this.videos);

  @override
  List<Object> get props => [videos];
}

class FreeClassesError extends FreeClassesState {
  final String message;

  const FreeClassesError(this.message);

  @override
  List<Object> get props => [message];
} 