import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_master_data_model.dart';

abstract class TeacherMasterDataRemoteDataSource {
  Future<TeacherMasterDataModel?> getTeacherMasterData(String teacherId);
}

class TeacherMasterDataRemoteDataSourceImpl implements TeacherMasterDataRemoteDataSource {
  final FirebaseFirestore firestore;

  TeacherMasterDataRemoteDataSourceImpl({required this.firestore});

  @override
  Future<TeacherMasterDataModel?> getTeacherMasterData(String teacherId) async {
    try {
      print('📦 [API REQUEST] TeacherMasterDataDataSource.getTeacherMasterData called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('master_teacher')
          .where('teacherId', isEqualTo: teacherId)
          .limit(1)
          .get();
      
      print('📦 [API RESPONSE] Found ${querySnapshot.docs.length} master data documents for teacherId: $teacherId');
      
      if (querySnapshot.docs.isEmpty) {
        print('📦 [API RESPONSE] No master data found for teacherId: $teacherId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final masterData = TeacherMasterDataModel.fromFirestore(doc);
      
      print('📦 [API RESPONSE] Successfully parsed master data: ${masterData.grades.length} grades, ${masterData.subjects.length} subjects');
      return masterData;
    } catch (e) {
      print('📦 [API ERROR] Error fetching teacher master data: $e');
      throw Exception('Failed to fetch teacher master data: $e');
    }
  }
}

