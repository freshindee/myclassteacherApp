import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_master_data_model.dart';

abstract class TeacherMasterDataRemoteDataSource {
  Future<TeacherMasterDataModel?> getTeacherMasterData(String schoolId);
}

class TeacherMasterDataRemoteDataSourceImpl implements TeacherMasterDataRemoteDataSource {
  final FirebaseFirestore firestore;

  TeacherMasterDataRemoteDataSourceImpl({required this.firestore});

  @override
  Future<TeacherMasterDataModel?> getTeacherMasterData(String schoolId) async {
    try {
      print('📦 [API REQUEST] TeacherMasterDataDataSource.getTeacherMasterData called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('master_teacher')
          .limit(1)
          .get();
      
      print('📦 [API RESPONSE] Found ${querySnapshot.docs.length} master data documents for schoolId: $schoolId');
      
      if (querySnapshot.docs.isEmpty) {
        print('📦 [API RESPONSE] No master data found for schoolId: $schoolId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['teacherId'] = schoolId;
      final masterData = TeacherMasterDataModel.fromJson(data);
      
      print('📦 [API RESPONSE] Successfully parsed master data: ${masterData.grades.length} grades, ${masterData.subjects.length} subjects');
      return masterData;
    } catch (e) {
      print('📦 [API ERROR] Error fetching teacher master data: $e');
      throw Exception('Failed to fetch teacher master data: $e');
    }
  }
}

