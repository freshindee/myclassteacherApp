part of 'term_test_paper_bloc.dart';

class TermTestPaperEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchTermTestPapers extends TermTestPaperEvent {
  final String teacherId;
  final String? grade;
  final String? subject;
  final int? term;

  FetchTermTestPapers({required this.teacherId, this.grade, this.subject, this.term});

  @override
  List<Object?> get props => [teacherId, grade, subject, term];
} 