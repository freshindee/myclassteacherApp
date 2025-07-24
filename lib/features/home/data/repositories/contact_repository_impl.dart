import 'package:dartz/dartz.dart';
import 'dart:developer' as developer;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/contact_remote_data_source.dart';
import '../models/contact_model.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ContactRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Contact>>> getContacts() async {
    if (await networkInfo.isConnected) {
      try {
        developer.log('📱 Fetching contacts from repository...', name: 'ContactRepository');
        final contactModels = await remoteDataSource.getContacts();
        developer.log('📱 Converting ${contactModels.length} contact models to entities', name: 'ContactRepository');
        
        final contacts = contactModels.map((model) => Contact(
          id: model.id,
          role: model.role,
          name: model.name,
          image: model.image,
          phone1: model.phone1,
          phone2: model.phone2,
          email: model.email,
          address: model.address,
          website: model.website,
          youtubeLink: model.youtubeLink,
          facebookLink: model.facebookLink,
          whatsappLink: model.whatsappLink,
          description: model.description,
          isActive: model.isActive,
        )).toList();

        developer.log('✅ Successfully converted ${contacts.length} contacts', name: 'ContactRepository');
        return Right(contacts);
      } catch (e) {
        developer.log('❌ Failed to fetch contacts: ${e.toString()}', name: 'ContactRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      developer.log('❌ No internet connection for contacts', name: 'ContactRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Contact>> getContactById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        developer.log('📱 Fetching contact by ID from repository: $id', name: 'ContactRepository');
        final contactModel = await remoteDataSource.getContactById(id);
        developer.log('📱 Converting contact model to entity', name: 'ContactRepository');
        
        final contact = Contact(
          id: contactModel.id,
          role: contactModel.role,
          name: contactModel.name,
          image: contactModel.image,
          phone1: contactModel.phone1,
          phone2: contactModel.phone2,
          email: contactModel.email,
          address: contactModel.address,
          website: contactModel.website,
          youtubeLink: contactModel.youtubeLink,
          facebookLink: contactModel.facebookLink,
          whatsappLink: contactModel.whatsappLink,
          description: contactModel.description,
          isActive: contactModel.isActive,
        );

        developer.log('✅ Successfully converted contact: ${contact.name}', name: 'ContactRepository');
        return Right(contact);
      } catch (e) {
        developer.log('❌ Failed to fetch contact by ID: ${e.toString()}', name: 'ContactRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      developer.log('❌ No internet connection for contact', name: 'ContactRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 