import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_page.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/video.dart';
import 'free_videos_bloc.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/master_data_service.dart';

class FreeVideosPage extends StatefulWidget {
  const FreeVideosPage({super.key});

  @override
  State<FreeVideosPage> createState() => _FreeVideosPageState();
}

class _FreeVideosPageState extends State<FreeVideosPage> {
  String? selectedGrade;
  String? teacherId;
  List<String> grades = [];
  bool _isLoadingGrades = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _loadGrades();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      teacherId = user?.teacherId ?? '';
    });
    print('🎬 [DEBUG] FreeVideosPage - Loaded teacherId: "$teacherId"');
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoadingGrades = true;
    });
    
    try {
      // First try to get from teacher master data
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.grades.isNotEmpty) {
        setState(() {
          grades = masterData.grades;
          _isLoadingGrades = false;
        });
        print('🎬 [DEBUG] FreeVideosPage - Loaded ${grades.length} grades from master data');
        return;
      }
      
      // Fallback to Grade entities from master data
      final gradeEntities = await MasterDataService.getGrades();
      if (gradeEntities.isNotEmpty) {
        setState(() {
          grades = gradeEntities.map((g) => g.name).toList();
          _isLoadingGrades = false;
        });
        print('🎬 [DEBUG] FreeVideosPage - Loaded ${grades.length} grades from Grade entities');
        return;
      }
      
      // If no grades found, set empty list
      setState(() {
        grades = [];
        _isLoadingGrades = false;
      });
      print('⚠️ [DEBUG] FreeVideosPage - No grades found in master data');
    } catch (e) {
      print('⚠️ [DEBUG] FreeVideosPage - Error loading grades: $e');
      setState(() {
        grades = [];
        _isLoadingGrades = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (teacherId == null || _isLoadingGrades) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Free Videos'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Don't allow interaction if teacherId is empty
    if (teacherId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Free Videos'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Teacher ID not found. Please login again.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Videos'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('පන්තිය තෝරන්න : ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: grades.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'No grades available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : DropdownButton<String>(
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
                            if (teacherId!.isNotEmpty) {
                              if (grade != null) {
                                print('🎬 [DEBUG] FreeVideosPage - Calling LoadFreeVideosByGrade with teacherId: "$teacherId", grade: "$grade"');
                                context.read<FreeVideosBloc>().add(LoadFreeVideosByGrade(teacherId!, grade));
                              } else {
                                print('🎬 [DEBUG] FreeVideosPage - Calling LoadFreeVideos with teacherId: "$teacherId"');
                                context.read<FreeVideosBloc>().add(LoadFreeVideos(teacherId!));
                              }
                            } else {
                              print('🎬 [DEBUG] FreeVideosPage - Skipping API call due to empty teacherId');
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<FreeVideosBloc, FreeVideosState>(
              builder: (context, state) {
                if (selectedGrade == null) {
                  return const Center(
                    child: Text('වීඩියෝ නැරබීමට පන්තිය තෝරන්න.'),
                  );
                }
                if (state is FreeVideosLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading free videos...'),
                      ],
                    ),
                  );
                } else if (state is FreeVideosLoaded) {
                  return _buildVideoList(context, state.videos);
                } else if (state is FreeVideosError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (teacherId!.isNotEmpty && selectedGrade != null) {
                              print('🎬 [DEBUG] FreeVideosPage - Retry - Calling LoadFreeVideosByGrade with teacherId: "$teacherId", grade: "$selectedGrade"');
                              context.read<FreeVideosBloc>().add(LoadFreeVideosByGrade(teacherId!, selectedGrade!));
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No videos available'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedGrade != null && teacherId!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                print('🎬 [DEBUG] FreeVideosPage - Refresh - Calling LoadFreeVideosByGrade with teacherId: "$teacherId", grade: "$selectedGrade"');
                context.read<FreeVideosBloc>().add(LoadFreeVideosByGrade(teacherId!, selectedGrade!));
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildVideoList(BuildContext context, List<Video> videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No free videos available'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(context, video);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVideoPlayer(context, video.youtubeUrl),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: video.thumb.isNotEmpty
                    ? Image.network(
                        video.thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No Thumbnail', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No Thumbnail', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (video.grade != null || video.subject != null) ...[
                    Row(
                      children: [
                        if (video.grade != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Grade ${video.grade}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (video.subject != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              video.subject!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  void _navigateToVideoPlayer(BuildContext context, String youtubeUrl) {
    if (youtubeUrl.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(videoUrl: youtubeUrl),
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
  }
} 