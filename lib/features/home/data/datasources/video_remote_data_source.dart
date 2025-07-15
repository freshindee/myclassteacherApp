import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/video_model.dart';
import '../../domain/usecases/add_video.dart';

abstract class VideoRemoteDataSource {
  Future<List<VideoModel>> getVideos({
    String? userId,
    String? grade,
    String? subject,
    int? month,
    int? year,
  });
  Future<VideoModel> addVideo(AddVideoParams params);
  Future<List<VideoModel>> getFreeVideos();
  Future<List<VideoModel>> getFreeVideosByGrade(String grade);
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  final FirebaseFirestore firestore;

  VideoRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<VideoModel>> getVideos({
    String? userId,
    String? grade,
    String? subject,
    int? month,
    int? year,
  }) async {
    try {
      print('🎬 VideoDataSource.getVideos called with parameters:');
      print('🎬   - userId: $userId');
      print('🎬   - grade: $grade');
      print('🎬   - subject: $subject');
      print('🎬   - month: $month');
      print('🎬   - year: $year');
      
      developer.log('🔍 Fetching videos from Firestore for userId: $userId...', name: 'VideoDataSource');
      
      Query<Map<String, dynamic>> collectionRef = firestore.collection('videos');
      print('🎬 Starting Firestore query on "videos" collection');

      if (grade != null && grade.isNotEmpty) {
        collectionRef = collectionRef.where('grade', isEqualTo: grade);
        print('🎬 Applied filter: grade = $grade');
      }
      if (subject != null && subject.isNotEmpty) {
        collectionRef = collectionRef.where('subject', isEqualTo: subject);
        print('🎬 Applied filter: subject = $subject');
      }
      if (month != null) {
        collectionRef = collectionRef.where('month', isEqualTo: month);
        print('🎬 Applied filter: month = $month');
      }
      if (year != null) {
        collectionRef = collectionRef.where('year', isEqualTo: year);
        print('🎬 Applied filter: year = $year');
      }

      final querySnapshot = await collectionRef.get();
      
      developer.log('📊 Found ${querySnapshot.docs.length} video documents', name: 'VideoDataSource');
      
      final videos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        developer.log('📹 Video document ${doc.id}: $data', name: 'VideoDataSource');
        
        return VideoModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      developer.log('✅ Successfully parsed ${videos.length} videos', name: 'VideoDataSource');
      return videos;
    } catch (e) {
      developer.log('❌ Error fetching videos: $e', name: 'VideoDataSource');
      throw Exception('Failed to fetch videos: $e');
    }
  }

  @override
  Future<VideoModel> addVideo(AddVideoParams params) async {
    try {
      developer.log('📝 Adding new video to Firestore...', name: 'VideoDataSource');
      
      final videoData = {
        'title': params.title,
        'description': params.description,
        'youtube_url': params.youtubeUrl,
        'thumb': params.thumb,
        'grade': params.grade,
        'subject': params.subject,
        'accessLevel': params.accessLevel,
        'created_at': FieldValue.serverTimestamp(),
      };

      final docRef = await firestore.collection('videos').add(videoData);
      
      developer.log('✅ Video added successfully with ID: ${docRef.id}', name: 'VideoDataSource');
      
      final videoModel = VideoModel(
        id: docRef.id,
        title: params.title,
        description: params.description,
        youtubeUrl: params.youtubeUrl,
        thumb: params.thumb,
        grade: params.grade,
        subject: params.subject,
        accessLevel: params.accessLevel,
      );
      
      return videoModel;
    } catch (e) {
      developer.log('❌ Error adding video: $e', name: 'VideoDataSource');
      throw Exception('Failed to add video: $e');
    }
  }

  @override
  Future<List<VideoModel>> getFreeVideos() async {
    try {
      developer.log('🔍 Fetching free videos from Firestore...', name: 'VideoDataSource');
      
      // First try to get videos with accessLevel = 'free'
      var querySnapshot = await firestore.collection('videos').where('accessLevel', isEqualTo: 'free').get();
      
      // If no results, try to get all videos and filter them
      if (querySnapshot.docs.isEmpty) {
        developer.log('📝 No videos found with accessLevel = "free", fetching all videos...', name: 'VideoDataSource');
        querySnapshot = await firestore.collection('videos').get();
      }
      
      developer.log('📊 Found ${querySnapshot.docs.length} video documents', name: 'VideoDataSource');
      
      final videos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        developer.log('📹 Free video document ${doc.id}: $data', name: 'VideoDataSource');
        
        return VideoModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      developer.log('✅ Successfully parsed ${videos.length} free videos', name: 'VideoDataSource');
      return videos;
    } catch (e) {
      developer.log('❌ Error fetching free videos: $e', name: 'VideoDataSource');
      throw Exception('Failed to fetch free videos: $e');
    }
  }

  @override
  Future<List<VideoModel>> getFreeVideosByGrade(String grade) async {
    try {
      developer.log('🔍 Fetching free videos for grade $grade from Firestore...', name: 'VideoDataSource');
      var querySnapshot = await firestore.collection('videos')
        .where('accessLevel', isEqualTo: 'free')
        .where('grade', isEqualTo: grade)
        .get();
      developer.log('📊 Found ${querySnapshot.docs.length} free video documents for grade $grade', name: 'VideoDataSource');
      final videos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        developer.log('📹 Free video document ${doc.id}: $data', name: 'VideoDataSource');
        return VideoModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      developer.log('✅ Successfully parsed ${videos.length} free videos for grade $grade', name: 'VideoDataSource');
      return videos;
    } catch (e) {
      developer.log('❌ Error fetching free videos for grade $grade: $e', name: 'VideoDataSource');
      throw Exception('Failed to fetch free videos for grade $grade: $e');
    }
  }
} 