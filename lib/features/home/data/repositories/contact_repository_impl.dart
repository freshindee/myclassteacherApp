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
  Future<Either<Failure, List<Contact>>> getContacts(String teacherId) async {
    print('📞 [REPOSITORY] ContactRepository.getContacts called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📞 [REPOSITORY] Network connected, calling remote data source...');
        final contactModels = await remoteDataSource.getContacts(teacherId);
        print('📞 [REPOSITORY] Successfully fetched ${contactModels.length} contact models from remote data source');
        
        final contacts = contactModels.map((model) => Contact(
          id: model.id,
          role: model.role,
          name: model.name,
          phone1: model.phone1,
          phone2: model.phone2,
          email: model.email,
          address: model.address,
          website: model.website,
          description: model.description,
          isActive: model.isActive,
          whatsappLink: model.whatsappLink,
          facebookLink: model.facebookLink,
          youtubeLink: model.youtubeLink,
          image: model.image,
        )).toList();
        
        print('📞 [REPOSITORY] Successfully converted ${contacts.length} contact models to entities');
        return Right(contacts);
      } catch (e) {
        print('📞 [REPOSITORY ERROR] Failed to fetch contacts: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📞 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Contact?>> getContactById(String teacherId, String contactId) async {
    print('📞 [REPOSITORY] ContactRepository.getContactById called with teacherId: $teacherId, contactId: $contactId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📞 [REPOSITORY] Network connected, calling remote data source...');
        final contactModel = await remoteDataSource.getContactById(teacherId, contactId);
        
        if (contactModel == null) {
          print('📞 [REPOSITORY] Contact not found for contactId: $contactId');
          return const Right(null);
        }
        
        print('📞 [REPOSITORY] Successfully fetched contact model from remote data source');
        
        final contact = Contact(
          id: contactModel.id,
          role: contactModel.role,
          name: contactModel.name,
          phone1: contactModel.phone1,
          phone2: contactModel.phone2,
          email: contactModel.email,
          address: contactModel.address,
          website: contactModel.website,
          description: contactModel.description,
          isActive: contactModel.isActive,
          whatsappLink: contactModel.whatsappLink,
          facebookLink: contactModel.facebookLink,
          youtubeLink: contactModel.youtubeLink,
          image: contactModel.image,
        );
        
        print('📞 [REPOSITORY] Successfully converted contact model to entity: ${contact.name}');
        return Right(contact);
      } catch (e) {
        print('📞 [REPOSITORY ERROR] Failed to fetch contact by ID: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📞 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 