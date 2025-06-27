import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classes/features/home/presentation/pages/video_player_page.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/add_video.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'class_videos_bloc.dart';

class ClassVideosPage extends StatelessWidget {
  const ClassVideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      // User is not logged in, show a message and a login button
      return Scaffold(
        appBar: AppBar(
          title: const Text('Class Videos'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'You need to be logged in to view class videos.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login Page'),
              ),
            ],
          ),
        ),
      );
    }

    final userId = user.id;

    return BlocProvider(
      create: (_) =>
          sl<ClassVideosBloc>()..add(FetchClassVideos(userId: userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Class Videos'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.refresh),
          //     onPressed: () {
          //       context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId));
          //     },
          //   ),
          //   // Temporary test button
          //   IconButton(
          //     icon: const Icon(Icons.add),
          //     onPressed: () async {
          //       await _addTestVideo(context, userId);
          //     },
          //   ),
          // ],
        ),
        body: BlocBuilder<ClassVideosBloc, ClassVideosState>(
          builder: (context, state) {
            developer.log('ClassVideosPage state: $state', name: 'ClassVideosPage');
            
            if (state is ClassVideosLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading videos...'),
                  ],
                ),
              );
            } else if (state is ClassVideosLoaded) {
              developer.log('Loaded ${state.videos.length} videos', name: 'ClassVideosPage');
              // Debug widget
              return Column(
                children: [
                  Expanded(
                    child: state.videos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.video_library_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No videos available',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adding some videos using the "Add Video" button',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/add-video');
                                  },
                                  child: const Text('Add Video'),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _addTestVideo(context, userId);
                                  },
                                  child: const Text('Add Test Video'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.videos.length,
                            itemBuilder: (context, index) {
                              final video = state.videos[index];
                              final isPaid = video.accessLevel == 'paid';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                elevation: 4,
                                child: ListTile(
                                  leading: Image.network(
                                    video.thumb,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.video_library, size: 50),
                                  ),
                                  title: Text(video.title),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(video.description),
                                      if (video.grade != null)
                                        Text('Grade: ${video.grade}'),
                                      if (video.subject != null)
                                        Text('Subject: ${video.subject}'),
                                    ],
                                  ),
                                  trailing: isPaid
                                      ? const Icon(Icons.lock, color: Colors.amber)
                                      : const Icon(Icons.lock_open, color: Colors.green),
                                  onTap: () {
                                    if (video.youtubeUrl.isNotEmpty) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => VideoPlayerPage(videoUrl: video.youtubeUrl),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Video URL is not available.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            } else if (state is ClassVideosError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
                child: Text('Select a class to see the videos.'));
          },
        ),
      ),
    );
  }

  Future<void> _addTestVideo(BuildContext context, String userId) async {
    try {
      final addVideo = sl<AddVideo>();
      final params = AddVideoParams(
        title: 'Test Video - Flutter Tutorial',
        description: 'This is a test video to verify the video functionality works correctly.',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        thumb: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        grade: 'Grade 10',
        subject: 'Computer Science',
        accessLevel: 'free',
      );

      final result = await addVideo(params);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add test video: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (video) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test video added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the video list
          context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId));
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 