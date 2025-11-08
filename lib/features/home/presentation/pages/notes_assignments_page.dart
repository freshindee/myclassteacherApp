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
  final String? initialGrade;
  final int? initialMonth;

  const NotesAssignmentsPage({
    super.key,
    this.initialGrade,
    this.initialMonth,
  });

  @override
  State<NotesAssignmentsPage> createState() => _NotesAssignmentsPageState();
}

class _NotesAssignmentsPageState extends State<NotesAssignmentsPage> {
  String? selectedGrade;
  String? teacherId;
  bool _hasLoadedNotes = false;
  final Map<String, bool> _downloadingNotes = {}; // Track downloading state per note

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.initialGrade;
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
        builder: (context) {
          // Auto-load notes if initialGrade is provided (only once)
          if (selectedGrade != null && teacherId != null && teacherId!.isNotEmpty && !_hasLoadedNotes) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                setState(() {
                  _hasLoadedNotes = true;
                });
                context.read<NotesAssignmentsBloc>().add(LoadNotesByGrade(teacherId!, selectedGrade!));
              }
            });
          }
          
          return Scaffold(
              appBar: AppBar(
                title: const Text('සටහන් / ප්‍රශ්න පත්‍ර'),
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              body: BlocBuilder<NotesAssignmentsBloc, NotesAssignmentsState>(
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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _downloadingNotes[note.id] == true
                                      ? null
                                      : () => _openPdf(context, note.pdfUrl),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _downloadingNotes[note.id] == true
                                      ? null
                                      : () => _downloadPdf(context, note),
                                  icon: _downloadingNotes[note.id] == true
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.download, size: 18),
                                  label: Text(_downloadingNotes[note.id] == true ? 'Downloading...' : 'Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
          );
        },
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

  Future<void> _downloadPdf(BuildContext context, Note note) async {
    if (note.pdfUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No PDF URL available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Set downloading state
    setState(() {
      _downloadingNotes[note.id] = true;
    });

    try {
      // Open PDF URL with default PDF viewer
      // This allows users to view and save the PDF to their preferred location
      final Uri pdfUri = Uri.parse(note.pdfUrl);
      
      if (await canLaunchUrl(pdfUri)) {
        await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF opened. Use the share/save option in the PDF viewer to save it.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Could not open PDF URL');
      }
    } catch (e) {
      developer.log('❌ Error opening PDF: $e', name: 'NotesAssignmentsPage');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Clear downloading state
      if (mounted) {
        setState(() {
          _downloadingNotes[note.id] = false;
        });
      }
    }
  }
} 