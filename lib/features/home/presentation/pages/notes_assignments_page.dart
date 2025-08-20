import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/get_notes_by_grade.dart';
import '../../../../core/services/user_session_service.dart';

part 'notes_assignments_bloc.dart';
part 'notes_assignments_event.dart';
part 'notes_assignments_state.dart';

class NotesAssignmentsPage extends StatefulWidget {
  const NotesAssignmentsPage({super.key});

  @override
  State<NotesAssignmentsPage> createState() => _NotesAssignmentsPageState();
}

class _NotesAssignmentsPageState extends State<NotesAssignmentsPage> {
  String? selectedGrade;
  String? teacherId;

  final List<String> grades = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      teacherId = user?.teacherId ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (teacherId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (context) => sl<NotesAssignmentsBloc>(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('සටහන් / ප්‍රශ්න පත්‍ර'),
            backgroundColor: Colors.orange[700],
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
                          if (grade != null) {
                            print('[NotesAssignmentsPage] Selected grade: $grade');
                            print('[NotesAssignmentsPage] Dispatching LoadNotesByGrade for: $grade');
                            context.read<NotesAssignmentsBloc>().add(LoadNotesByGrade(teacherId!, grade));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<NotesAssignmentsBloc, NotesAssignmentsState>(
                  builder: (context, state) {
                    if (selectedGrade == null) {
                      return const Center(
                        child: Text('සටහන් / ප්‍රශ්න පත්‍ර ලබාගැනීමට පන්තිය තෝරන්න'),
                      );
                    }
                    if (state is NotesAssignmentsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is NotesAssignmentsLoaded) {
                      if (state.notes.isEmpty) {
                        return const Center(
                          child: Text(
                            'මෙම පන්තිය සදහා සටහන් නොමැත.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notes.length,
                        itemBuilder: (context, index) {
                          final note = state.notes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _openPdf(context, note.pdfUrl),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Grade: " + note.grade,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      note.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      note.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is NotesAssignmentsError) {
                      return Center(
                        child: Text(state.message),
                      );
                    }
                    return const Center(child: Text('No notes or assignments found.'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, String pdfUrl) async {
    if (pdfUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No PDF URL available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('PDF Viewer'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.network(pdfUrl),
        ),
      ),
    );
  }
} 