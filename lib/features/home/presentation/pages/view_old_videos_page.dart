import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classes/features/home/presentation/pages/video_player_page.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'old_videos_bloc.dart';

class ViewOldVideoPage extends StatefulWidget {
  const ViewOldVideoPage({super.key});

  @override
  State<ViewOldVideoPage> createState() => _ViewOldVideoPageState();
}

class _ViewOldVideoPageState extends State<ViewOldVideoPage> {
  String? selectedGrade;
  final List<String> grades = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      // User is not logged in, show a message and a login button
      return Scaffold(
        appBar: AppBar(
          title: const Text('පසුගිය වීඩියෝ'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'You need to be logged in to view old videos.',
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

    final userId = user.userId;

    return BlocProvider(
      create: (_) => sl<OldVideosBloc>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('පසුගිය වීඩියෝ '),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('පන්තිය තෝරන්න: ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedGrade,
                          hint: const Text('All'),
                          isExpanded: true,
                          items: grades.map((grade) {
                            return DropdownMenuItem(
                              value: grade,
                              child: Text('Grade $grade'),
                            );
                          }).toList(),
                          onChanged: (grade) {
                            setState(() {
                              selectedGrade = grade;
                            });
                            // Dispatch event to fetch old videos for selected grade
                            context.read<OldVideosBloc>().add(
                              FetchOldVideos(userId: userId, grade: grade),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedGrade == null
                      ? const Center(child: Text('පසුගිය වීඩියෝ නැරබීමට පන්තිය තෝරන්න.'))
                      : BlocBuilder<OldVideosBloc, OldVideosState>(
                          builder: (context, state) {
                            developer.log('ViewOldVideoPage state: $state', name: 'ViewOldVideoPage');

                            if (state is OldVideosLoading) {
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
                            } else if (state is OldVideosLoaded) {
                              developer.log('Loaded ${state.videos.length} old videos', name: 'ViewOldVideoPage');
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
                                                  'No old videos available',
                                                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
                                                      if (video.month != null)
                                                        Text('Month: ${video.month}'),
                                                      if (video.year != null)
                                                        Text('Year: ${video.year}'),
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
                            } else if (state is OldVideosError) {
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
                                        context.read<OldVideosBloc>().add(FetchOldVideos(userId: userId, grade: selectedGrade));
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const Center(
                                child: Text('No videos to display.'));
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 