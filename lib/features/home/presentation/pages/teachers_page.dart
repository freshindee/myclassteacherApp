import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/teacher.dart';
import 'teachers_bloc.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TeachersBloc>()..add(LoadTeachers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Our Teachers'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TeachersBloc, TeachersState>(
          builder: (context, state) {
            if (state is TeachersLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TeachersLoaded) {
              return _buildTeacherList(context, state.teachers);
            } else if (state is TeachersError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No teachers available'));
          },
        ),
      ),
    );
  }

  Widget _buildTeacherList(BuildContext context, List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return const Center(child: Text('No teachers found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherCard(context, teacher);
      },
    );
  }

  Widget _buildTeacherCard(BuildContext context, Teacher teacher) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: teacher.image.isNotEmpty
                  ? Image.network(
                      teacher.image,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 80),
                    )
                  : const Icon(Icons.person, size: 120),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade: ${teacher.grade}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(teacher.phone, style: const TextStyle(fontSize: 13)),
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