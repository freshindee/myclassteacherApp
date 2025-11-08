import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'video_player_page.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'old_videos_bloc.dart';

class ViewOldVideoPage extends StatefulWidget {
  final String? grade;
  final int? month;
  final String? subject;

  const ViewOldVideoPage({
    super.key,
    this.grade,
    this.month,
    this.subject,
  });

  @override
  State<ViewOldVideoPage> createState() => _ViewOldVideoPageState();
}

class _ViewOldVideoPageState extends State<ViewOldVideoPage> {

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
    final teacherId = user.teacherId ?? '';

    if (teacherId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පසුගිය වීඩියෝ'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Teacher ID not found. Please contact support.'),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<OldVideosBloc>(),
      child: Builder(
        builder: (context) {
          // Auto-load videos when page loads with provided parameters
          final now = DateTime.now();
          final currentYear = now.year;
          
          // Extract grade number from "Grade X" format if needed
          String? gradeValue = widget.grade;
          if (gradeValue != null && gradeValue.contains('Grade')) {
            gradeValue = gradeValue.replaceAll(RegExp(r'[^0-9]'), '');
          }
          
          // Load videos on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<OldVideosBloc>().add(
              FetchOldVideos(
                userId: userId,
                teacherId: teacherId,
                grade: gradeValue,
                subject: widget.subject,
                month: widget.month,
                year: currentYear,
              ),
            );
          });
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('පසුගිය වීඩියෝ '),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: BlocBuilder<OldVideosBloc, OldVideosState>(
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
                  return state.videos.isEmpty
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
                          padding: const EdgeInsets.all(16),
                          itemCount: state.videos.length,
                          itemBuilder: (context, index) {
                            final video = state.videos[index];
                            final isPaid = video.accessLevel == 'paid';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    video.thumb,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.video_library, size: 50),
                                  ),
                                ),
                                title: Text(
                                  video.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
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
                            final now = DateTime.now();
                            final currentYear = now.year;
                            String? gradeValue = widget.grade;
                            if (gradeValue != null && gradeValue.contains('Grade')) {
                              gradeValue = gradeValue.replaceAll(RegExp(r'[^0-9]'), '');
                            }
                            context.read<OldVideosBloc>().add(
                              FetchOldVideos(
                                userId: userId,
                                teacherId: teacherId,
                                grade: gradeValue,
                                subject: widget.subject,
                                month: widget.month,
                                year: currentYear,
                              ),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text('No videos to display.'),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 