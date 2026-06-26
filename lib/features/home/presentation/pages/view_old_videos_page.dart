import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/youtube_thumbnail_player.dart';
import '../../../../core/widgets/youtube_webview_player_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ViewOldVideoPage extends StatefulWidget {
  final String? grade;
  final int? month;
  final String? subject;
  final String? classSubjectId;

  const ViewOldVideoPage({
    super.key,
    this.grade,
    this.month,
    this.subject,
    this.classSubjectId,
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

    final schoolId = user.teacherId ?? '';

    if (schoolId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පසුගිය වීඩියෝ'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('School not found. Please contact support.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('පසුගිය වීඩියෝ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildVideoList(context, schoolId),
    );
  }

  /// Loads videos from local DB (school_content_videos). Filters by class_subject_id and selected month.
  Widget _buildVideoList(BuildContext context, String schoolId) {
    final classSubjectId = widget.classSubjectId;
    final selectedMonth = widget.month;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentVideos(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        }
        final all = snapshot.data ?? [];
        final list = all.where((item) {
          final csId = item['class_subject_id']?.toString()?.trim();
          if (classSubjectId != null && classSubjectId.isNotEmpty) {
            if (csId == null || csId != classSubjectId) return false;
          } else if (csId == null || csId.isEmpty) {
            return false;
          }
          if (selectedMonth != null) {
            final itemMonth = item['month'];
            if (itemMonth != null) {
              final m = itemMonth is int ? itemMonth : int.tryParse(itemMonth.toString());
              if (m != null && m != selectedMonth) return false;
            }
          }
          return true;
        }).toList();

        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No videos for this month and subject',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => _buildVideoCard(context, list[index]),
        );
      },
    );
  }

  /// Video list item card: same design as ClassVideosPage — thumbnail, title, description, grade/subject tags, Watch Video.
  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> video) {
    final title = video['title']?.toString().trim() ?? 'Video';
    final description = video['description']?.toString().trim() ?? '';
    final grade = video['grade']?.toString().trim();
    final subject = video['subject']?.toString().trim();
    final videoUrl = (video['video_url'] ?? video['youtube_url'])?.toString().trim() ?? '';
    final thumbUrl = video['thumb']?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (videoUrl.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => YoutubeWebViewPlayerPage(
                  videoUrl: videoUrl,
                  title: title,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video URL is not available.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubeThumbnailPlayer(
              videoUrl: videoUrl,
              thumbUrl: thumbUrl,
              title: title,
              aspectRatio: 16 / 9,
              borderRadius: 12,
              showSnackBarOnInvalidUrl: true,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((grade != null && grade.isNotEmpty) || (subject != null && subject.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (grade != null && grade.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              grade.toUpperCase().startsWith('GRADE') ? grade : 'Grade $grade',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (subject != null && subject.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.play_circle_filled, size: 22, color: Colors.red[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

} 