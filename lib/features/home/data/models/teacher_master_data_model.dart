import '../../domain/entities/teacher_master_data.dart';
import '../../domain/entities/teacher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_model.dart';

class TeacherMasterDataModel extends TeacherMasterData {
  const TeacherMasterDataModel({
    required super.teacherId,
    required super.grades,
    required super.subjects,
    required super.pricing,
    required super.teachers,
    super.bankDetails,
    super.sliderImages,
    super.createdAt,
    super.updatedAt,
  });

  factory TeacherMasterDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse grades array
    final gradesList = data['grades'] as List<dynamic>? ?? [];
    final grades = gradesList.map((e) => e.toString()).toList();
    
    // Parse subjects array
    final subjectsList = data['subjects'] as List<dynamic>? ?? [];
    final subjects = subjectsList.map((e) => e.toString()).toList();
    
    // Parse pricing object
    final pricingData = data['pricing'] as Map<String, dynamic>? ?? {};
    final Map<String, Map<String, int>> pricing = {};
    pricingData.forEach((subject, gradePrices) {
      if (gradePrices is Map) {
        final Map<String, int> gradePriceMap = {};
        gradePrices.forEach((grade, price) {
          if (price is int) {
            gradePriceMap[grade.toString()] = price;
          } else if (price is num) {
            gradePriceMap[grade.toString()] = price.toInt();
          }
        });
        pricing[subject] = gradePriceMap;
      }
    });
    
    // Parse teachers array
    final teachersList = data['teachers'] as List<dynamic>? ?? [];
    final List<Teacher> teachers = teachersList.map((teacherData) {
      if (teacherData is Map<String, dynamic>) {
        final teacherModel = TeacherModel.fromJson(teacherData);
        return teacherModel.toEntity();
      }
      return Teacher(
        id: '',
        name: '',
        subject: '',
        grade: '',
        image: '',
      );
    }).toList();
    
    // Parse bank_details array
    final bankDetailsList = data['bank_details'] as List<dynamic>? ?? [];
    final bankDetails = bankDetailsList.map((e) => e.toString()).toList();
    
    // Parse sliderImages array
    final sliderImagesList = data['sliderImages'] as List<dynamic>? ?? [];
    final sliderImages = sliderImagesList.map((e) => e.toString()).toList();
    
    // Parse timestamps
    DateTime? createdAt;
    DateTime? updatedAt;
    if (data['createdAt'] != null) {
      final ts = data['createdAt'];
      if (ts is Timestamp) {
        createdAt = ts.toDate();
      } else if (ts is DateTime) {
        createdAt = ts;
      }
    }
    if (data['updatedAt'] != null) {
      final ts = data['updatedAt'];
      if (ts is Timestamp) {
        updatedAt = ts.toDate();
      } else if (ts is DateTime) {
        updatedAt = ts;
      }
    }
    
    return TeacherMasterDataModel(
      teacherId: data['teacherId'] as String? ?? '',
      grades: grades,
      subjects: subjects,
      pricing: pricing,
      teachers: teachers,
      bankDetails: bankDetails,
      sliderImages: sliderImages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'grades': grades,
      'subjects': subjects,
      'pricing': pricing,
      'teachers': teachers.map((teacher) => {
        'id': teacher.id,
        'name': teacher.name,
        'subject': teacher.subject,
        'grade': teacher.grade,
        'image': teacher.image,
        'phone': teacher.phone,
        'display_id': teacher.displayId,
      }).toList(),
      'bank_details': bankDetails,
      'sliderImages': sliderImages,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  TeacherMasterData toEntity() {
    return TeacherMasterData(
      teacherId: teacherId,
      grades: grades,
      subjects: subjects,
      pricing: pricing,
      teachers: teachers,
      bankDetails: bankDetails,
      sliderImages: sliderImages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

