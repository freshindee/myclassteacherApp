import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

class GetContacts implements UseCase<List<Contact>, NoParams> {
  final ContactRepository repository;
  GetContacts(this.repository);
  
  @override
  Future<Either<Failure, List<Contact>>> call(NoParams params) async {
    return await repository.getContacts();
  }
} 