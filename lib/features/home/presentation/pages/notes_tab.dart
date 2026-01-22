import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:developer' as developer;
import '../../../../injection_container.dart';
import '../../domain/entities/note.dart';
import '../../../../core/services/user_session_service.dart';
import 'free_notes_bloc.dart';

class NotesTab extends StatefulWidget {
  final List<String> grades;

  const NotesTab({
    super.key,
    required this.grades,
  });

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String? selectedGrade;
  String? teacherId;
  bool _isLoadingTeacherId = true;
  final Map<String, bool> _downloadingNotes = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      teacherId = user?.teacherId ?? '';
      _isLoadingTeacherId = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTeacherId) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teacherId == null || teacherId!.isEmpty) {
      return const Center(
        child: Text('Teacher ID not found. Please login again.'),
      );
    }

    return BlocProvider(
      create: (context) => sl<FreeNotesBloc>(),
      child: _NotesTabContent(
        grades: widget.grades,
        selectedGrade: selectedGrade,
        teacherId: teacherId ?? '',
        onGradeChanged: (grade) {
          setState(() {
            selectedGrade = grade;
          });
        },
      ),
    );
  }
}

class _NotesTabContent extends StatefulWidget {
  final List<String> grades;
  final String? selectedGrade;
  final String teacherId;
  final Function(String?) onGradeChanged;

  const _NotesTabContent({
    required this.grades,
    required this.selectedGrade,
    required this.teacherId,
    required this.onGradeChanged,
  });

  @override
  State<_NotesTabContent> createState() => _NotesTabContentState();
}

class _NotesTabContentState extends State<_NotesTabContent> {
  final Map<String, bool> _downloadingNotes = {};

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
                child: widget.grades.isEmpty
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
                        value: widget.selectedGrade,
                        hint: const Text('All'),
                        isExpanded: true,
                        items: widget.grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text('Grade $grade'),
                          );
                          }).toList(),
                        onChanged: (grade) {
                          widget.onGradeChanged(grade);
                          if (widget.teacherId.isNotEmpty) {
                            // Use grade number directly as stored in Firestore (e.g., "8" not "Grade 8")
                            print('📝 [DEBUG] NotesTab - Grade selected: "$grade", teacherId: "${widget.teacherId}"');
                            print('📝 [DEBUG] NotesTab - Calling LoadFreeNotes event');
                            context.read<FreeNotesBloc>().add(LoadFreeNotes(widget.teacherId, grade: grade));
                          } else {
                            print('📝 [WARNING] NotesTab - Cannot load notes: teacherId is empty');
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<FreeNotesBloc, FreeNotesState>(
            builder: (context, state) {
                print('📝 [DEBUG] NotesTab - BlocBuilder state: ${state.runtimeType}');
                if (widget.selectedGrade == null) {
                  return const Center(
                    child: Text('සටහන් නැරබීමට පන්තිය තෝරන්න.'),
                  );
                }
                // If state is initial and grade is selected, trigger load
                if (state is FreeNotesInitial && widget.selectedGrade != null && widget.teacherId.isNotEmpty) {
                  // Trigger load on first build when grade is selected
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      print('📝 [DEBUG] NotesTab - Auto-loading notes for grade: ${widget.selectedGrade}');
                      context.read<FreeNotesBloc>().add(LoadFreeNotes(widget.teacherId, grade: widget.selectedGrade));
                    }
                  });
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading free notes...'),
                      ],
                    ),
                  );
                }
                if (state is FreeNotesLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading free notes...'),
                      ],
                    ),
                  );
                } else if (state is FreeNotesLoaded) {
                  print('📝 [DEBUG] NotesTab - FreeNotesLoaded with ${state.notes.length} notes');
                  if (state.notes.isEmpty) {
                    print('📝 [DEBUG] NotesTab - Notes list is empty');
                  } else {
                    print('📝 [DEBUG] NotesTab - Notes: ${state.notes.map((n) => n.title).toList()}');
                  }
                  return _buildNotesList(context, state.notes);
                } else if (state is FreeNotesError) {
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
                            if (widget.teacherId.isNotEmpty && widget.selectedGrade != null) {
                              // Use grade number directly as stored in Firestore (e.g., "8" not "Grade 8")
                              print('📝 [DEBUG] NotesTab - Retry - Calling LoadFreeNotes with teacherId: "${widget.teacherId}", grade: "${widget.selectedGrade}"');
                              context.read<FreeNotesBloc>().add(LoadFreeNotes(widget.teacherId, grade: widget.selectedGrade));
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
                      Icon(Icons.note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notes available'),
                    ],
                  ),
                );
              },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList(BuildContext context, List<Note> notes) {
    if (notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('මෙම පන්තිය සදහා නොමිලේ සටහන් නොමැත.'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(context, note);
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
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
                "Grade: ${note.grade}",
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
            backgroundColor: Colors.blue,
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
      developer.log('❌ Error opening PDF: $e', name: 'NotesTab');
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
