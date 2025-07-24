import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classes/features/home/presentation/pages/video_player_page.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/add_video.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'class_videos_bloc.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';

class ClassVideosPage extends StatefulWidget {
  const ClassVideosPage({super.key});

  @override
  State<ClassVideosPage> createState() => _ClassVideosPageState();
}

class _ClassVideosPageState extends State<ClassVideosPage> {
  String? selectedGrade;
  String? selectedSubject;
  final List<String> grades = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];
  final List<String> subjects = [
    'Mathematics', 'Science', 'English', 'ICT', 'Tamil', 'Sinhala'
  ];

  List<dynamic> currentMonthPayments = [];
  bool paymentsLoading = false;
  bool paymentsLoaded = false;
  String? paymentsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());
  }

  Future<void> _fetchPayments() async {
    setState(() {
      paymentsLoading = true;
      paymentsError = null;
    });
    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;
      if (user == null) return;
      final userId = user.userId;
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      // Assume you have a payment repository or service available via sl<...>()
      final getUserPayments = sl.get<GetUserPayments>();
      final params = GetUserPaymentsParams(userId: userId);
      final result = await getUserPayments(params);
      result.fold(
        (failure) {
          setState(() {
            paymentsError = failure.message;
            paymentsLoading = false;
            paymentsLoaded = false;
          });
        },
        (payments) {
          final filtered = payments.where((p) => p.month == currentMonth && p.year == currentYear && p.status == 'approved').toList();
          setState(() {
            currentMonthPayments = filtered;
            paymentsLoading = false;
            paymentsLoaded = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        paymentsError = e.toString();
        paymentsLoading = false;
        paymentsLoaded = false;
      });
    }
  }

  void _onGradeOrSubjectChanged(String? grade, String? subject, String userId, BuildContext context) {
    setState(() {
      selectedGrade = grade;
      selectedSubject = subject;
    });
    if (grade != null && subject != null && paymentsLoaded) {
      final hasPayment = currentMonthPayments.any((p) => p.grade == grade && p.subject == subject);
      if (!hasPayment) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Payment Found'),
            content: Text('You have not paid for Grade $grade - $subject for this month.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      context.read<ClassVideosBloc>().add(
        FetchClassVideos(userId: userId, grade: grade, subject: subject, payments: currentMonthPayments),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      // User is not logged in, show a message and a login button
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති වීඩියෝ නරබන්න '),
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

    final userId = user.userId;
    
    // Log the parameters being sent for video fetching
    developer.log('🎬 ClassVideosPage: Fetching videos with userId: $userId', name: 'ClassVideosPage');
    print('🎬 ClassVideosPage: Fetching videos with userId: $userId');

    return BlocProvider(
      create: (_) => sl<ClassVideosBloc>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('පන්ති වීඩියෝ නරබන්න '),
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
            body: Column(
              children: [
                if (paymentsLoading)
                  const LinearProgressIndicator(),
                if (paymentsError != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading payments: ', style: TextStyle(color: Colors.red)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('පන්තිය තෝරන්න : ', style: TextStyle(fontSize: 16)),
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
                                _onGradeOrSubjectChanged(grade, selectedSubject, userId, context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('විෂයය තෝරන්න : ', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedSubject,
                              hint: const Text('All'),
                              isExpanded: true,
                              items: subjects.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(subject),
                                );
                              }).toList(),
                              onChanged: (subject) {
                                _onGradeOrSubjectChanged(selectedGrade, subject, userId, context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: (!paymentsLoaded)
                      ? const Center(child: Text('Loading your payment data...'))
                      : (selectedGrade == null || selectedSubject == null)
                        ? const Center(child: Text('වීඩියෝ නැරබීමට පන්තිය සහ විෂයය තෝරන්න'))
                        : BlocBuilder<ClassVideosBloc, ClassVideosState>(
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
                                          context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId, payments: currentMonthPayments));
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
              ],
            ),
          );
        },
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
          context.read<ClassVideosBloc>().add(FetchClassVideos(userId: userId, payments: currentMonthPayments));
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