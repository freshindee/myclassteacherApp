import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String subject;
  final String teacherId;

  const Subject({
    required this.id,
    required this.subject,
    required this.teacherId,
  });

  @override
  List<Object?> get props => [id, subject, teacherId];
}

