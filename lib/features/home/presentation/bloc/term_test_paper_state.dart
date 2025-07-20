part of 'term_test_paper_bloc.dart';

abstract class TermTestPaperState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TermTestPaperLoading extends TermTestPaperState {}

class TermTestPaperLoaded extends TermTestPaperState {
  final List<TermTestPaper> papers;
  TermTestPaperLoaded(this.papers);

  @override
  List<Object?> get props => [papers];
}

class TermTestPaperError extends TermTestPaperState {
  final String message;
  TermTestPaperError(this.message);

  @override
  List<Object?> get props => [message];
} 