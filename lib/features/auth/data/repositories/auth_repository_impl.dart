import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> signIn(String phoneNumber, String password) async {
    try {
      print('🔐 AuthRepository: Calling remote data source for sign in');
      final userModel = await remoteDataSource.signIn(phoneNumber, password);
      
      print('🔐 AuthRepository: Received user model from data source:');
      print('🔐   - userId: ${userModel.userId}');
      print('🔐   - phoneNumber: ${userModel.phoneNumber}');
      
      final user = User(
        userId: userModel.userId,
        phoneNumber: userModel.phoneNumber,
        password: userModel.password,
        name: userModel.name,
        birthday: userModel.birthday,
        district: userModel.district,
      );
      
      print('🔐 AuthRepository: Created user entity with userId: ${user.userId}');
      
      return Right(user);
    } catch (e) {
      print('❌ AuthRepository: Sign in failed: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
  ) async {
    try {
      final userModel = await remoteDataSource.signUp(
        phoneNumber, 
        password,
        name,
        birthday,
        district,
      );
      return Right(User(
        userId: userModel.userId,
        phoneNumber: userModel.phoneNumber,
        password: userModel.password,
        name: userModel.name,
        birthday: userModel.birthday,
        district: userModel.district,
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