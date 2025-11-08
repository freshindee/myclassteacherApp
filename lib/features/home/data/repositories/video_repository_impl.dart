import 'package:dartz/dartz.dart';
import 'dart:developer' as developer;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/video_remote_data_source.dart';
import '../models/video_model.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/add_video.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  VideoRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Video>>> getVideos({
    String? userId,
    String? teacherId,
    String? grade,
    String? subject,
    int? month,
    int? year,
    String? accessLevel,
  }) async {
    print('🎬 [REPOSITORY] VideoRepository.getVideos called with:');
    print('🎬   - userId: $userId');
    print('🎬   - teacherId: $teacherId');
    print('🎬   - grade: $grade');
    print('🎬   - subject: $subject');
    print('🎬   - month: $month');
    print('🎬   - year: $year');
    print('🎬   - accessLevel: $accessLevel');
    
    if (await networkInfo.isConnected) {
      try {
        print('🎬 [REPOSITORY] Network connected, calling remote data source...');
        final videoModels = await remoteDataSource.getVideos(
          userId: userId,
          teacherId: teacherId,
          grade: grade,
          subject: subject,
          month: month,
          year: year,
          accessLevel: accessLevel,
        );
        developer.log('📱 Converting ${videoModels.length} video models to entities', name: 'VideoRepository');
        
        final videos = videoModels.map((model) => Video(
          id: model.id,
          title: model.title,
          description: model.description,
          youtubeUrl: model.youtubeUrl,
          thumb: model.thumb,
          grade: model.grade,
          subject: model.subject,
          accessLevel: model.accessLevel,
          month: model.month,
          year: model.year,
        )).toList();

        print('🎬 [REPOSITORY] Successfully converted ${videos.length} video models to entities');
        return Right(videos);
      } catch (e) {
        print('🎬 [REPOSITORY ERROR] Failed to fetch videos: $e');
        developer.log('❌ Failed to fetch videos: ${e.toString()}', name: 'VideoRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🎬 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Video>> addVideo(AddVideoParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final videoModel = await remoteDataSource.addVideo(params);
        developer.log('📱 Converting video model to entity', name: 'VideoRepository');
        
        final video = Video(
          id: videoModel.id,
          title: videoModel.title,
          description: videoModel.description,
          youtubeUrl: videoModel.youtubeUrl,
          thumb: videoModel.thumb,
          grade: videoModel.grade,
          subject: videoModel.subject,
          accessLevel: videoModel.accessLevel,
          month: videoModel.month,
          year: videoModel.year,
        );

        return Right(video);
      } catch (e) {
        developer.log('❌ Failed to add video: ${e.toString()}', name: 'VideoRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }

  Future<String?> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final fileBytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      final path = 'videos/  ${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      developer.log('❌ Failed to upload file: $e', name: 'VideoRepository');
      return null;
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getFreeVideos(String teacherId) async {
    print('🎬 [REPOSITORY] VideoRepository.getFreeVideos called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('🎬 [REPOSITORY] Network connected, calling remote data source...');
        developer.log('📱 Fetching free videos from repository...', name: 'VideoRepository');
        final videoModels = await remoteDataSource.getFreeVideos(teacherId);
        developer.log('📱 Converting ${videoModels.length} free video models to entities', name: 'VideoRepository');
        
        final videos = videoModels.map((model) => Video(
          id: model.id,
          title: model.title,
          description: model.description,
          youtubeUrl: model.youtubeUrl,
          thumb: model.thumb,
          grade: model.grade,
          subject: model.subject,
          accessLevel: model.accessLevel,
          month: model.month,
          year: model.year,
        )).toList();

        print('🎬 [REPOSITORY] Successfully converted ${videos.length} free video models to entities');
        developer.log('✅ Successfully converted ${videos.length} free videos', name: 'VideoRepository');
        return Right(videos);
      } catch (e) {
        print('🎬 [REPOSITORY ERROR] Failed to fetch free videos: $e');
        developer.log('❌ Failed to fetch free videos: ${e.toString()}', name: 'VideoRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🎬 [REPOSITORY ERROR] No internet connection');
      developer.log('❌ No internet connection for free videos', name: 'VideoRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getFreeVideosByGrade(String teacherId, String grade) async {
    print('🎬 [REPOSITORY] VideoRepository.getFreeVideosByGrade called with teacherId: $teacherId, grade: $grade');
    
    if (await networkInfo.isConnected) {
      try {
        print('🎬 [REPOSITORY] Network connected, calling remote data source...');
        developer.log('📱 Fetching free videos by grade from repository...', name: 'VideoRepository');
        final videoModels = await remoteDataSource.getFreeVideosByGrade(teacherId, grade);
        developer.log('📱 Converting ${videoModels.length} free video models to entities', name: 'VideoRepository');
        
        final videos = videoModels.map((model) => Video(
          id: model.id,
          title: model.title,
          description: model.description,
          youtubeUrl: model.youtubeUrl,
          thumb: model.thumb,
          grade: model.grade,
          subject: model.subject,
          accessLevel: model.accessLevel,
          month: model.month,
          year: model.year,
        )).toList();

        print('🎬 [REPOSITORY] Successfully converted ${videos.length} free video models to entities for grade $grade');
        developer.log('✅ Successfully converted ${videos.length} free videos for grade $grade', name: 'VideoRepository');
        return Right(videos);
      } catch (e) {
        print('🎬 [REPOSITORY ERROR] Failed to fetch free videos by grade: $e');
        developer.log('❌ Failed to fetch free videos: ${e.toString()}', name: 'VideoRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🎬 [REPOSITORY ERROR] No internet connection');
      developer.log('❌ No internet connection for free videos', name: 'VideoRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 