import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

class GetContacts implements UseCase<List<Contact>, String> {
  final ContactRepository repository;
  GetContacts(this.repository);
  
  @override
  Future<Either<Failure, List<Contact>>> call(String teacherId) async {
    return await repository.getContacts(teacherId);
  }
} 