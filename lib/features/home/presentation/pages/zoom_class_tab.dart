import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/today_class.dart';
import 'today_classes_bloc.dart';

class ZoomClassTab extends StatelessWidget {
  final String? selectedGrade;
  final String? teacherId;
  final List<String> grades;
  final Function(String?) onGradeChanged;

  const ZoomClassTab({
    super.key,
    required this.selectedGrade,
    required this.teacherId,
    required this.grades,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TodayClassesBloc>(),
      child: _ZoomClassTabContent(
        selectedGrade: selectedGrade,
        teacherId: teacherId,
        grades: grades,
        onGradeChanged: onGradeChanged,
      ),
    );
  }
}

class _ZoomClassTabContent extends StatelessWidget {
  final String? selectedGrade;
  final String? teacherId;
  final List<String> grades;
  final Function(String?) onGradeChanged;

  const _ZoomClassTabContent({
    required this.selectedGrade,
    required this.teacherId,
    required this.grades,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                          onGradeChanged(grade);
                          if (teacherId != null && teacherId!.isNotEmpty && grade != null) {
                            // Format grade to match Firestore format: "Grade 7" instead of "7"
                            final formattedGrade = 'Grade $grade';
                            print('📚 [DEBUG] ZoomClassTab - Calling LoadTodayClasses with teacherId: "$teacherId", grade: "$formattedGrade"');
                            context.read<TodayClassesBloc>().add(LoadTodayClasses(teacherId!, grade: formattedGrade));
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<TodayClassesBloc, TodayClassesState>(
            builder: (context, state) {
              if (selectedGrade == null) {
                return const Center(
                  child: Text('අද දින පන්ති නැරබීමට පන්තිය තෝරන්න.'),
                );
              }
              if (state is TodayClassesLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading today classes...'),
                    ],
                  ),
                );
              } else if (state is TodayClassesLoaded) {
                // Filter classes to only show those with accessLevel = "free"
                final freeClasses = state.classes.where((cls) => cls.accessLevel == 'free').toList();
                return _buildZoomClassList(context, freeClasses);
              } else if (state is TodayClassesError) {
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
                          if (teacherId != null && teacherId!.isNotEmpty && selectedGrade != null) {
                            // Format grade to match Firestore format: "Grade 7" instead of "7"
                            final formattedGrade = 'Grade $selectedGrade';
                            print('📚 [DEBUG] ZoomClassTab - Retry - Calling LoadTodayClasses with teacherId: "$teacherId", grade: "$formattedGrade"');
                            context.read<TodayClassesBloc>().add(LoadTodayClasses(teacherId!, grade: formattedGrade));
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
                    Icon(Icons.video_call, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No classes available'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoomClassList(BuildContext context, List<TodayClass> classes) {
    if (classes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('අද දින පන්ති නොමැත.'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final todayClass = classes[index];
        return _buildZoomClassCard(context, todayClass);
      },
    );
  }

  Widget _buildZoomClassCard(BuildContext context, TodayClass todayClass) {
    String? teacherImage;
    final teacherIdInt = int.tryParse(todayClass.teacherId);
    if (teacherIdInt != null) {
      switch (teacherIdInt) {
        case 1:
          teacherImage = 'assets/images/aruna2.jpeg';
          break;
        case 6:
          teacherImage = 'assets/images/samu2.jpeg';
          break;
        case 4:
          teacherImage = 'assets/images/mahesh.jpeg';
          break;
        case 2:
          teacherImage = 'assets/images/sajith.jpeg';
          break;
        case 5:
          teacherImage = 'assets/images/indika.png';
          break;
        case 3:
          teacherImage = 'assets/images/mana.jpeg';
          break;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teacherImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  teacherImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            if (teacherImage != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayClass.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayClass.grade,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teacher: ${todayClass.teacher}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${todayClass.time}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // Zoom class ID - always display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.video_call, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Zoom class ID: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            (todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty) 
                                ? todayClass.zoomId! 
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty)
                                  ? Colors.blue.shade900
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Password - always display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Password: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            (todayClass.password != null && todayClass.password!.isNotEmpty) 
                                ? todayClass.password! 
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (todayClass.password != null && todayClass.password!.isNotEmpty)
                                  ? Colors.orange.shade900
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _shareZoomLink(context, todayClass),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _joinZoomClass(context, todayClass.joinUrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Join Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareZoomLink(BuildContext context, TodayClass todayClass) async {
    try {
      // Build share text with class details
      final shareText = '''
${todayClass.subject} - ${todayClass.grade}
Teacher: ${todayClass.teacher}
Time: ${todayClass.time}
${todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty ? 'Zoom ID: ${todayClass.zoomId}' : ''}
${todayClass.password != null && todayClass.password!.isNotEmpty ? 'Password: ${todayClass.password}' : ''}

Join Link: ${todayClass.joinUrl}
''';
      
      await Share.share(
        shareText,
        subject: '${todayClass.subject} Class - ${todayClass.grade}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinZoomClass(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not join class'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
