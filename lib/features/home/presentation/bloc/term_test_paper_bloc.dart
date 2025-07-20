import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/term_test_paper.dart';
import '../../domain/usecases/get_term_test_papers.dart';
import 'package:equatable/equatable.dart';

part 'term_test_paper_event.dart';
part 'term_test_paper_state.dart';

class TermTestPaperBloc extends Bloc<TermTestPaperEvent, TermTestPaperState> {
  final GetTermTestPapers getTermTestPapers;

  TermTestPaperBloc({required this.getTermTestPapers}) : super(TermTestPaperLoading()) {
    on<FetchTermTestPapers>(_onFetch);
  }

  Future<void> _onFetch(FetchTermTestPapers event, Emitter<TermTestPaperState> emit) async {
    emit(TermTestPaperLoading());
    try {
      final papers = await getTermTestPapers(
        grade: event.grade,
        subject: event.subject,
        term: event.term,
      );
      emit(TermTestPaperLoaded(papers));
    } catch (e) {
      emit(TermTestPaperError(e.toString()));
    }
  }
} 