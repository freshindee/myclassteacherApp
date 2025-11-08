import '../../domain/entities/grade.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GradeModel extends Grade {
  const GradeModel({
    required super.id,
    required super.name,
    required super.teacherId,
  });

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GradeModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
    };
  }

  Grade toEntity() {
    return Grade(
      id: id,
      name: name,
      teacherId: teacherId,
    );
  }
}

