import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../domain/usecases/get_exam_chapters.dart';
import '../../domain/entities/exam_chapter.dart';
import 'exam_papers_list_page.dart';

class OnlineExamSelectionPage extends StatefulWidget {
  const OnlineExamSelectionPage({super.key, this.embedInHomeShell = false});

  /// When true, [HomePage] shows the app bar; hide local [AppBar].
  final bool embedInHomeShell;

  @override
  State<OnlineExamSelectionPage> createState() => _OnlineExamSelectionPageState();
}

class _OnlineExamSelectionPageState extends State<OnlineExamSelectionPage> {
  String? selectedGrade;
  String? schoolId;
  String? selectedClassName;
  Map<String, dynamic>? selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  String? selectedSubject; // display name from class_subject chip

  ExamChapter? selectedChapter;
  List<ExamChapter> _chapters = [];
  bool _isLoadingChapters = false;
  String? _chaptersError;

  bool _schoolIdLoading = true;

  final GetExamChapters _getExamChapters = sl<GetExamChapters>();

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final user = await UserSessionService.getCurrentUser();
    if (mounted) {
      setState(() {
        schoolId = user?.teacherId ?? '';
        _schoolIdLoading = false;
      });
    }
  }

  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  /// Selected class_subject id (string) - sent to APIs as subject_id.
  String? _getSelectedClassSubjectId() {
    if (selectedSubject == null || selectedSubject!.isEmpty) return null;
    for (final item in _classSubjectsForSelectedClass) {
      if (_subjectDisplayName(item) == selectedSubject) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
        return null;
      }
    }
    return null;
  }

  /// User-friendly message when no exam chapters/papers exist for the subject.
  static const String _noChaptersMessage =
      'මෙම විෂය සඳහා විභාග පත්‍රිකා තවම ලබා දී නැත. ඉක්මනින් ඔබට පෙනෙනු ඇත.';

  static String _chaptersErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('no chapters found') ||
        lower.contains('chapters found for this subject') ||
        lower.contains('no exam chapters')) {
      return _noChaptersMessage;
    }
    return raw;
  }

  Future<void> _loadChapters(String subjectId) async {
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
          if (mounted) {
            setState(() {
              _chaptersError = _chaptersErrorMessage(failure.message);
              _chapters = [];
              _isLoadingChapters = false;
            });
          }
        },
        (chapters) {
          print('✅ [DEBUG] OnlineExamSelectionPage - Successfully loaded ${chapters.length} chapters from API');
          if (mounted) {
            setState(() {
              _chapters = chapters;
              _isLoadingChapters = false;
            });
          }
        },
      );
    } catch (e) {
      print('❌ [DEBUG] OnlineExamSelectionPage - Error loading chapters: $e');
      if (mounted) {
        setState(() {
          _chaptersError = _chaptersErrorMessage(e.toString());
          _chapters = [];
          _isLoadingChapters = false;
        });
      }
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
    final classSubjectId = _getSelectedClassSubjectId();
    if (classSubjectId == null || classSubjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('විෂය තෝරාගැනීමට පන්තිය සහ විෂය තෝරන්න'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamPapersListPage(
          grade: selectedGrade!,
          subjectId: 0,
          chapterId: selectedChapter?.id,
          subjectName: selectedSubject!,
          chapterName: selectedChapter?.name,
          classSubjectId: classSubjectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolIdLoading) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('අන්තර්ජාල විභාග'),
                centerTitle: true,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final schoolId = this.schoolId ?? '';

    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
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
            const Icon(Icons.quiz, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'විභාගයක් තෝරාගැනීමට ශ්‍රේණිය සහ විෂය තෝරන්න',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            GradeSelector(
              value: selectedGrade,
              label: 'පන්තිය',
              hint: 'පන්තිය තෝරන්න',
              onGradeSelected: (value) async {
                setState(() {
                  selectedGrade = value;
                  selectedClassName = null;
                  selectedClassDoc = null;
                  selectedSubject = null;
                  selectedChapter = null;
                  _classesForGrade = [];
                  _classSubjectsForSelectedClass = [];
                  _subjectIdToName = {};
                  _chapters = [];
                });
                if (value != null && value.isNotEmpty && schoolId.isNotEmpty) {
                  setState(() => _loadingClasses = true);
                  final cache = sl<SchoolCacheService>();
                  final list = await cache.getClassesByGradeNumber(schoolId, value);
                  if (mounted) {
                    setState(() {
                      _classesForGrade = list;
                      _loadingClasses = false;
                      if (list.length == 1) {
                        selectedClassDoc = list.first;
                        selectedClassName = SchoolCacheService.classDisplayName(list.first, value);
                      }
                    });
                    if (list.length == 1 && list.first.isNotEmpty && schoolId.isNotEmpty) {
                      setState(() => _loadingClassSubjects = true);
                      final cache = sl<SchoolCacheService>();
                      final doc = list.first;
                      final classId = doc['id']?.toString() ?? '';
                      final cName = SchoolCacheService.classDisplayName(doc, value);
                      final subjects = await cache.getClassSubjectsForClass(schoolId, classId, cName);
                      final subjectDocs = await cache.getSubjects(schoolId);
                      final idToName = <String, String>{};
                      for (final s in subjectDocs) {
                        final id = s['id']?.toString();
                        if (id == null) continue;
                        final name = s['subject'] ?? s['name'] ?? s['title'];
                        if (name != null && name.toString().trim().isNotEmpty) {
                          idToName[id] = name.toString().trim();
                        }
                      }
                      if (mounted) {
                        setState(() {
                          _classSubjectsForSelectedClass = subjects;
                          _subjectIdToName = idToName;
                          _loadingClassSubjects = false;
                        });
                      }
                    }
                  }
                }
              },
            ),

            if (selectedGrade != null && selectedGrade!.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (_loadingClasses)
                const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
              else if (_classesForGrade.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'මෙම පන්තිය සඳහා පන්ති නොමැත',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedClassName != null &&
                          _classesForGrade.any((c) =>
                              SchoolCacheService.classDisplayName(c, selectedGrade!) == selectedClassName)
                      ? selectedClassName
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'පන්තියේ නම',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('පන්තිය තෝරන්න'),
                  items: _classesForGrade.map((c) {
                    final name = SchoolCacheService.classDisplayName(c, selectedGrade!);
                    return DropdownMenuItem<String>(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) async {
                    final className = value ?? '';
                    final doc = _classesForGrade.cast<Map<String, dynamic>>().firstWhere(
                          (c) => SchoolCacheService.classDisplayName(c, selectedGrade!) == className,
                          orElse: () => <String, dynamic>{},
                        );
                    setState(() {
                      selectedClassName = className;
                      selectedClassDoc = doc.isNotEmpty ? doc : null;
                      selectedSubject = null;
                      selectedChapter = null;
                      _classSubjectsForSelectedClass = [];
                      _subjectIdToName = {};
                      _chapters = [];
                    });
                    if (doc.isNotEmpty && schoolId.isNotEmpty) {
                      setState(() => _loadingClassSubjects = true);
                      final cache = sl<SchoolCacheService>();
                      final classId = doc['id']?.toString() ?? '';
                      final list = await cache.getClassSubjectsForClass(schoolId, classId, className);
                      final subjectDocs = await cache.getSubjects(schoolId);
                      final idToName = <String, String>{};
                      for (final s in subjectDocs) {
                        final id = s['id']?.toString();
                        if (id == null) continue;
                        final name = s['subject'] ?? s['name'] ?? s['title'];
                        if (name != null && name.toString().trim().isNotEmpty) {
                          idToName[id] = name.toString().trim();
                        }
                      }
                      if (mounted) {
                        setState(() {
                          _classSubjectsForSelectedClass = list;
                          _subjectIdToName = idToName;
                          _loadingClassSubjects = false;
                        });
                      }
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],

            if (selectedClassDoc != null && selectedClassName != null) ...[
              const SizedBox(height: 8),
              Text(
                'විෂය',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              if (_loadingClassSubjects)
                const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
              else if (_classSubjectsForSelectedClass.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'මෙම පන්තිය සඳහා විෂය නොමැත',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _classSubjectsForSelectedClass.map((item) {
                    final name = _subjectDisplayName(item);
                    final isSelected = selectedSubject == name;
                    return FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedSubject = isSelected ? null : name;
                          selectedChapter = null;
                          _chapters = [];
                        });
                        if (!isSelected) {
                          final id = item['id']?.toString();
                          if (id != null && id.isNotEmpty) _loadChapters(id);
                        }
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],

            if (selectedSubject != null) ...[
              const Text(
                'පාඩම්',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        setState(() => selectedChapter = selected ? chapter : null);
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
