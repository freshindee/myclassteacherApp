import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../../../core/usecases.dart';
import '../../domain/usecases/get_exam_subjects.dart';
import '../../domain/usecases/get_exam_chapters.dart';
import '../../domain/entities/exam_subject.dart';
import '../../domain/entities/exam_chapter.dart';
import 'exam_papers_list_page.dart';

class OnlineExamSelectionPage extends StatefulWidget {
  const OnlineExamSelectionPage({super.key});

  @override
  State<OnlineExamSelectionPage> createState() => _OnlineExamSelectionPageState();
}

class _OnlineExamSelectionPageState extends State<OnlineExamSelectionPage> {
  String? selectedGrade;
  ExamSubject? selectedSubject;
  ExamChapter? selectedChapter;

  // Hardcoded grades from 1 to 13
  final List<String> _grades = List.generate(13, (index) => (index + 1).toString());
  List<ExamSubject> _subjects = [];
  bool _isLoadingSubjects = true;
  String? _subjectsError;

  List<ExamChapter> _chapters = [];
  bool _isLoadingChapters = false;
  String? _chaptersError;

  final GetExamSubjects _getExamSubjects = sl<GetExamSubjects>();
  final GetExamChapters _getExamChapters = sl<GetExamChapters>();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
      _subjectsError = null;
    });
    
    try {
      print('📝 [DEBUG] OnlineExamSelectionPage - Starting to load subjects from API');
      
      final result = await _getExamSubjects(NoParams());
      
      result.fold(
        (failure) {
          print('❌ [DEBUG] OnlineExamSelectionPage - Failed to load subjects: ${failure.message}');
          setState(() {
            _subjectsError = failure.message;
            _subjects = [];
            _isLoadingSubjects = false;
          });
        },
        (subjects) {
          print('✅ [DEBUG] OnlineExamSelectionPage - Successfully loaded ${subjects.length} subjects from API');
          setState(() {
            _subjects = subjects;
            _isLoadingSubjects = false;
          });
        },
      );
    } catch (e) {
      print('❌ [DEBUG] OnlineExamSelectionPage - Error loading subjects: $e');
      setState(() {
        _subjectsError = e.toString();
        _subjects = [];
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadChapters(int subjectId) async {
    setState(() {
      _isLoadingChapters = true;
      _chaptersError = null;
      _chapters = [];
    });
    
    try {
      print('📝 [DEBUG] OnlineExamSelectionPage - Starting to load chapters for subjectId: $subjectId');
      
      final result = await _getExamChapters(subjectId);
      
      result.fold(
        (failure) {
          print('❌ [DEBUG] OnlineExamSelectionPage - Failed to load chapters: ${failure.message}');
          setState(() {
            _chaptersError = failure.message;
            _chapters = [];
            _isLoadingChapters = false;
          });
        },
        (chapters) {
          print('✅ [DEBUG] OnlineExamSelectionPage - Successfully loaded ${chapters.length} chapters from API');
          setState(() {
            _chapters = chapters;
            _isLoadingChapters = false;
          });
        },
      );
    } catch (e) {
      print('❌ [DEBUG] OnlineExamSelectionPage - Error loading chapters: $e');
      setState(() {
        _chaptersError = e.toString();
        _chapters = [];
        _isLoadingChapters = false;
      });
    }
  }

  void _onSearchExams() {
    if (selectedGrade == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('කරුණාකර ශ්‍රේණිය සහ විෂය තෝරන්න'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to exam papers list page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamPapersListPage(
          grade: selectedGrade!,
          subjectId: selectedSubject!.id,
          chapterId: selectedChapter?.id,
          subjectName: selectedSubject!.name,
          chapterName: selectedChapter?.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('අන්තර්ජාල විභාග'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            const Icon(
              Icons.quiz,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'විභාගයක් තෝරාගැනීමට ශ්‍රේණිය සහ විෂය තෝරන්න',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Grade Dropdown
            const Text(
              'ශ්‍රේණිය',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedGrade,
              decoration: const InputDecoration(
                labelText: 'ශ්‍රේණිය තෝරන්න',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: _grades.map((grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text('Grade $grade'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGrade = value;
                  // Clear subject selection when grade changes
                  selectedSubject = null;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Subject Dropdown
            const Text(
              'විෂය',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExamSubject>(
              value: selectedSubject,
              decoration: InputDecoration(
                labelText: 'විෂය තෝරන්න',
                border: const OutlineInputBorder(),
                errorText: _subjectsError != null ? _subjectsError : null,
                prefixIcon: const Icon(Icons.book),
              ),
              items: _isLoadingSubjects
                  ? [
                      const DropdownMenuItem<ExamSubject>(
                        value: null,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    ]
                  : _subjects.isEmpty
                      ? [
                          const DropdownMenuItem<ExamSubject>(
                            value: null,
                            child: Text('විෂය නොමැත'),
                          )
                        ]
                      : _subjects.map((subject) {
                          return DropdownMenuItem<ExamSubject>(
                            value: subject,
                            child: Text(subject.name),
                          );
                        }).toList(),
              onChanged: _isLoadingSubjects || _subjects.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        selectedSubject = value;
                        selectedChapter = null; // Clear chapter selection
                        _chapters = []; // Clear chapters list
                      });
                      // Load chapters when subject is selected
                      if (value != null) {
                        _loadChapters(value.id);
                      }
                    },
            ),
            const SizedBox(height: 24),
            
            // Chapters Section
            if (selectedSubject != null) ...[
              const Text(
                'පාඩම්',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingChapters)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_chaptersError != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _chaptersError!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_chapters.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'මෙම විෂය සඳහා පාඩම් නොමැත',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _chapters.map((chapter) {
                    final isSelected = selectedChapter?.id == chapter.id;
                    return FilterChip(
                      label: Text(chapter.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedChapter = selected ? chapter : null;
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],
            
            const SizedBox(height: 8),
            
            // Search Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _onSearchExams,
                icon: const Icon(Icons.search, size: 24),
                label: const Text(
                  'විභාග සොයන්න',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
