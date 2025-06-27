import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/usecases/get_teachers.dart';
import '../../../../core/usecases.dart';

part 'teachers_event.dart';
part 'teachers_state.dart';

class TeachersBloc extends Bloc<TeachersEvent, TeachersState> {
  final GetTeachers getTeachers;
  TeachersBloc({required this.getTeachers}) : super(TeachersInitial()) {
    on<LoadTeachers>(_onLoadTeachers);
  }

  Future<void> _onLoadTeachers(
    LoadTeachers event,
    Emitter<TeachersState> emit,
  ) async {
    emit(TeachersLoading());
    final result = await getTeachers(NoParams());
    result.fold(
      (failure) => emit(TeachersError(failure.toString())),
      (teachers) => emit(TeachersLoaded(teachers)),
    );
  }
} 