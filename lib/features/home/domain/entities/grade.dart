import 'package:equatable/equatable.dart';

class Grade extends Equatable {
  final String id;
  final String name;
  final String teacherId;

  const Grade({
    required this.id,
    required this.name,
    required this.teacherId,
  });

  @override
  List<Object> get props => [id, name, teacherId];
}

