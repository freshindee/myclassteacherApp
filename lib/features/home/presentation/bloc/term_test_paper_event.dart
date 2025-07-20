part of 'term_test_paper_bloc.dart';

class TermTestPaperEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchTermTestPapers extends TermTestPaperEvent {
  final String? grade;
  final String? subject;
  final int? term;

  FetchTermTestPapers({this.grade, this.subject, this.term});

  @override
  List<Object?> get props => [grade, subject, term];
} 