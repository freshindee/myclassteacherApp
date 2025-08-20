import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signIn(String teacherId, String whatsappNo, String password) async {
    print('🔐 [REPOSITORY] AuthRepository.signIn called with teacherId: $teacherId, whatsappNo: $whatsappNo');
    
    if (await networkInfo.isConnected) {
      try {
        print('🔐 [REPOSITORY] Network connected, calling remote data source...');
        final userModel = await remoteDataSource.signIn(teacherId, whatsappNo, password);
        print('🔐 [REPOSITORY] Successfully authenticated user with ID: ${userModel.userId}');
        
        final user = User(
          userId: userModel.userId,
          phoneNumber: userModel.phoneNumber,
          password: userModel.password,
          name: userModel.name,
          birthday: userModel.birthday,
          district: userModel.district,
          teacherId: userModel.teacherId,
        );
        
        print('🔐 [REPOSITORY] Successfully converted user model to entity with ID: ${user.userId}');
        return Right(user);
      } catch (e) {
        print('🔐 [REPOSITORY ERROR] Failed to sign in: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🔐 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
  ) async {
    try {
      final userModel = await remoteDataSource.signUp(
        phoneNumber, 
        password,
        name,
        birthday,
        district,
        teacherId,
      );
      return Right(User(
        userId: userModel.userId,
        phoneNumber: userModel.phoneNumber,
        password: userModel.password,
        name: userModel.name,
        birthday: userModel.birthday,
        district: userModel.district,
        teacherId: userModel.teacherId,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? phoneNumber,
    String? name,
    DateTime? birthday,
    String? district,
    String? newPassword,
  }) async {
    try {
      final updated = await remoteDataSource.updateUser(
        userId: userId,
        phoneNumber: phoneNumber,
        name: name,
        birthday: birthday,
        district: district,
        newPassword: newPassword,
      );
      return Right(User(
        userId: updated.userId,
        phoneNumber: updated.phoneNumber,
        password: '',
        name: updated.name,
        birthday: updated.birthday,
        district: updated.district,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}