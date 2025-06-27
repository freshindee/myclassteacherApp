import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/today_class.dart';
import 'today_classes_bloc.dart';

class TodayClassesPage extends StatelessWidget {
  const TodayClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TodayClassesBloc>()..add(LoadTodayClasses()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Today's Classes"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TodayClassesBloc, TodayClassesState>(
          builder: (context, state) {
            if (state is TodayClassesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TodayClassesLoaded) {
              return _buildClassList(context, state.classes);
            } else if (state is TodayClassesError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No classes available'));
          },
        ),
      ),
    );
  }

  Widget _buildClassList(BuildContext context, List<TodayClass> classes) {
    if (classes.isEmpty) {
      return const Center(child: Text('No classes for today.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final todayClass = classes[index];
        return _buildClassCard(context, todayClass);
      },
    );
  }

  Widget _buildClassCard(BuildContext context, TodayClass todayClass) {
    String? teacherImage;
    switch (todayClass.subject.toLowerCase()) {
      case 'english':
        teacherImage = 'assets/images/aruna2.jpeg';
        break;
      case 'mathematics':
        teacherImage = 'assets/images/mahesh.jpeg';
        break;
      case 'science':
        teacherImage = 'assets/images/sajith.jpeg';
        break;
      case 'ict':
        teacherImage = 'assets/images/indika.jpeg';
        break;
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
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _joinNow(context, todayClass.joinUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Join Now'),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _joinNow(BuildContext context, String url) async {
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