import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../../payment/presentation/pages/payment_page.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<GradesListPage> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  String? schoolId;
  String? selectedGrade;
  String? selectedClassId;
  /// When set, timetable list is filtered to this subject (subject_id or subject name); null = show all.
  String? selectedSubjectId;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _schoolIdLoading = true;
  bool _loadingClasses = false;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final id = await UserSessionService.getSchoolId();
    final details = await UserSessionService.getStudentDetails();
    final sid = id ?? details?['school_id']?.toString() ?? '';
    if (mounted) {
      setState(() {
        schoolId = sid;
        _schoolIdLoading = false;
      });
    }
  }

  bool _classGradeMatches(Map<String, dynamic> classDoc, String gradeNum) {
    final g = (classDoc['grade'] ?? classDoc['grade_number'] ?? classDoc['grade_id'])?.toString().trim() ?? '';
    if (g.isEmpty) return false;
    if (g == gradeNum) return true;
    final docNum = g.replaceAll(RegExp(r'[^0-9]'), '');
    final selNum = gradeNum.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return docNum.isNotEmpty && selNum.isNotEmpty && docNum == selNum;
  }

  Future<void> _loadClassesForGrade(String schoolId, String grade) async {
    if (!mounted) return;
    setState(() {
      _loadingClasses = true;
      selectedClassId = null;
      _classesForGrade = [];
    });
    final all = await sl<SchoolCacheService>().getClasses(schoolId);
    if (!mounted) return;
    final forGrade = all.where((c) => _classGradeMatches(c, grade)).toList();
    setState(() {
      _classesForGrade = forGrade;
      _loadingClasses = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolIdLoading) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('පන්ති කාල සටහන'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final schoolId = this.schoolId ?? '';
    if (schoolId.isEmpty) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('පන්ති කාල සටහන'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
        body: const Center(child: Text('School not found. Please login again.')),
      );
    }

    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text('පන්ති කාල සටහන'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GradeSelector(
              value: selectedGrade,
              label: 'පන්තිය',
              hint: 'පන්තිය තෝරන්න',
                onGradeSelected: (value) {
                setState(() {
                  selectedGrade = value;
                  selectedClassId = null;
                  selectedSubjectId = null;
                  _classesForGrade = [];
                });
                if (value != null && value.isNotEmpty && schoolId.isNotEmpty) {
                  _loadClassesForGrade(schoolId, value);
                }
              },
            ),
          ),
          if (selectedGrade != null && selectedGrade!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: selectedClassId != null && _classesForGrade.any((c) => (c['id']?.toString()) == selectedClassId) ? selectedClassId : null,
                decoration: InputDecoration(
                  labelText: 'පන්තිය (Class)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text(_loadingClasses ? 'පන්ති ලබා ගැනෙමින්...' : 'පන්තිය තෝරන්න'),
                items: _classesForGrade.map((c) {
                  final id = c['id']?.toString() ?? '';
                  final name = SchoolCacheService.classDisplayName(c, selectedGrade!);
                  return DropdownMenuItem<String>(value: id, child: Text(name));
                }).toList(),
                onChanged: _loadingClasses
                    ? null
                    : (value) {
                        setState(() {
                          selectedClassId = value;
                          selectedSubjectId = null;
                        });
                      },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: selectedGrade == null || selectedGrade!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('කාල සටහන නැරබීමට පන්තිය තෝරන්න'),
                      ],
                    ),
                  )
                : _buildTimetableList(context, schoolId),
          ),
        ],
      ),
    );
  }

  /// Returns all timetables for the selected grade (and optionally for the selected class).
  /// When [classId] is null or empty, returns all timetables for the grade. Otherwise filters by class_id as well.
  Future<({List<Map<String, dynamic>> list, int totalInCache})> _fetchTimetablesForGrade(String schoolId, String grade, String? classId) async {
    final gradeNum = grade.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final wantClassId = classId?.trim();
    print('📅 [GradesListPage] REQUEST: schoolId=$schoolId, grade=$grade, classId=$wantClassId');
    final all = await sl<SchoolCacheService>().getTimetables(schoolId);
    print('📅 [GradesListPage] CACHE: total timetables for school=${all.length}');
    final list = all.where((doc) {
      final docGrade = (doc['grade'] ?? doc['Grade'] ?? doc['grade_name'] ?? doc['grade_number'])?.toString().trim() ?? '';
      final docGradeNum = docGrade.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final gradeMatch = (docGradeNum.isNotEmpty && gradeNum.isNotEmpty && docGradeNum == gradeNum) ||
          docGrade.toLowerCase() == grade.toLowerCase() ||
          (docGradeNum.isEmpty && docGrade == grade);
      if (!gradeMatch) return false;
      if (wantClassId == null || wantClassId.isEmpty) return true;
      final docClassId = (doc['class_id'] ?? doc['classId'])?.toString().trim() ?? '';
      return docClassId.isEmpty || docClassId == wantClassId;
    }).toList();
    print('📅 [GradesListPage] FILTER: grade=$grade, classId=$wantClassId → ${list.length} items');
    return (list: list, totalInCache: all.length);
  }

  /// Unique subjects from timetable list: [{id, name}, ...]. Uses subject_id when present, else subject name.
  static List<Map<String, String>> _uniqueSubjectsFromList(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    final subjects = <Map<String, String>>[];
    for (final doc in list) {
      final id = (doc['subject_id'] ?? doc['subjectId'])?.toString().trim() ?? '';
      final name = (doc['subject'] ?? doc['Subject'] ?? doc['subject_name'] ?? doc['subjectName'])?.toString().trim() ?? '';
      final key = id.isNotEmpty ? id : name;
      final displayName = name.isNotEmpty ? name : (id.isNotEmpty ? id : 'Subject');
      if (key.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        subjects.add({'id': key, 'name': displayName});
      }
    }
    subjects.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return subjects;
  }

  static bool _docMatchesSubject(Map<String, dynamic> doc, String subjectId) {
    final id = (doc['subject_id'] ?? doc['subjectId'])?.toString().trim() ?? '';
    final name = (doc['subject'] ?? doc['Subject'] ?? doc['subject_name'] ?? doc['subjectName'])?.toString().trim() ?? '';
    return id == subjectId || (id.isEmpty && name == subjectId);
  }

  Widget _buildTimetableList(BuildContext context, String schoolId) {
    final grade = selectedGrade ?? '';
    final classId = selectedClassId;
    return FutureBuilder<({List<Map<String, dynamic>> list, int totalInCache})>(
      future: _fetchTimetablesForGrade(schoolId, grade, classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data;
        final list = result?.list ?? [];
        final totalInCache = result?.totalInCache ?? 0;
        if (list.isEmpty) {
          final noDataForSchool = totalInCache == 0;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  noDataForSchool
                      ? 'මෙම පාසල සඳහා කාල සටහන දත්ත නැත. සමමුහුර්ත කිරීමට නැවත පිවිසෙන්න.'
                      : 'මෙම පන්තිය සඳහා කාල සටහන නැත',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final uniqueSubjects = _uniqueSubjectsFromList(list);
        list.sort((a, b) {
          final indexA = a['index'] is int ? a['index'] as int : int.tryParse(a['index']?.toString() ?? '') ?? 0;
          final indexB = b['index'] is int ? b['index'] as int : int.tryParse(b['index']?.toString() ?? '') ?? 0;
          if (indexA != 0 || indexB != 0) {
            if (indexA != indexB) return indexA.compareTo(indexB);
          } else {
            final dayOfWeekA = a['day_of_week'] is int ? a['day_of_week'] as int : int.tryParse(a['day_of_week']?.toString() ?? '') ?? 0;
            final dayOfWeekB = b['day_of_week'] is int ? b['day_of_week'] as int : int.tryParse(b['day_of_week']?.toString() ?? '') ?? 0;
            if (dayOfWeekA != dayOfWeekB) return dayOfWeekA.compareTo(dayOfWeekB);
            final startA = a['start_time']?.toString() ?? '';
            final startB = b['start_time']?.toString() ?? '';
            if (startA != startB) return startA.compareTo(startB);
          }
          final dayA = a['day']?.toString() ?? '';
          final dayB = b['day']?.toString() ?? '';
          return dayA.compareTo(dayB);
        });
        // Filter by subject when selected
        final displayList = selectedSubjectId == null || selectedSubjectId!.isEmpty
            ? list
            : list.where((doc) => _docMatchesSubject(doc, selectedSubjectId!)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (uniqueSubjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'විෂය (Subject)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  hint: const Text('සියලු විෂයන්'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('සියලු විෂයන්')),
                    ...uniqueSubjects.map((s) => DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(s['name'] ?? s['id'] ?? ''),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => selectedSubjectId = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final doc = displayList[index];
                  return _buildTimetableCard(context, doc, schoolId);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// Timetable list item: header (grade), icon + subject/title/time, footer (day + action).
  /// DB keys: academic_year, chapter_name, class_id, class_subject_id, day, day_of_week, end_time, grade, room, start_time, subject, subject_id, teacher, teacher_id, status.
  Widget _buildTimetableCard(BuildContext context, Map<String, dynamic> doc, String schoolId) {
    // Support snake_case and camelCase / alternate keys from cache
    final grade = (doc['grade'] ?? doc['Grade'] ?? doc['grade_name'] ?? doc['grade_number'])?.toString().trim() ?? '';
    final subject = (doc['subject'] ?? doc['Subject'] ?? doc['subject_name'] ?? doc['subjectName'])?.toString().trim() ?? '';
    final chapterName = (doc['chapter_name'] ?? doc['chapterName'] ?? doc['topic'] ?? doc['title'])?.toString().trim() ?? '';
    final startTime = (doc['start_time'] ?? doc['startTime'])?.toString().trim() ?? '';
    final endTime = (doc['end_time'] ?? doc['endTime'])?.toString().trim() ?? '';
    // day = date (e.g. "2025-03-11"); day_of_week = day name string (e.g. "Monday")
    final String day = (doc['day'] ?? doc['Day'] ?? doc['day_name'])?.toString().trim() ?? '';
    final Object? dowRaw = doc['day_of_week'] ?? doc['dayOfWeek'];
    String dayOfWeekName = '';
    if (dowRaw != null) {
      final idx = dowRaw is int ? dowRaw : int.tryParse(dowRaw.toString().trim());
      if (idx != null && idx >= 1 && idx <= 7) {
        dayOfWeekName = _dayNames[idx - 1];
      } else if (idx == 0) {
        dayOfWeekName = 'Sunday';
      } else {
        final String dowStr = dowRaw.toString().trim();
        if (dowStr.isNotEmpty) {
          dayOfWeekName = dowStr; // day name: "Monday", "Tuesday", etc.
        }
      }
    }
    final teacher = (doc['teacher'] ?? doc['teacher_name'])?.toString().trim() ?? '';

    // Use selected grade from page when doc has no grade (we filtered by class_id)
    final effectiveGrade = grade.isEmpty ? (selectedGrade ?? '') : grade;
    final gradeNum = effectiveGrade.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final gradeLabel = effectiveGrade.isEmpty
        ? ''
        : (gradeNum.isNotEmpty ? 'GRADE $gradeNum' : (effectiveGrade.toUpperCase().startsWith('GRADE') ? effectiveGrade.toUpperCase() : 'GRADE ${effectiveGrade}'));

    final displaySubject = subject.isEmpty ? 'Lesson' : subject;

    String timeStr = '';
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      timeStr = '$startTime - $endTime';
    } else if (startTime.isNotEmpty) {
      timeStr = startTime;
    } else if (endTime.isNotEmpty) {
      timeStr = endTime;
    } else {
      final t = doc['time']?.toString().trim() ?? '';
      if (t.isNotEmpty) timeStr = t;
    }

    final headerColor = _headerColorForSubject(displaySubject);
    final iconColor = _iconColorForSubject(displaySubject);
    final iconData = _iconForSubject(displaySubject);
    // Highlighted text color for chapter name, time, and day
    const highlightColor = Colors.black87;
    const highlightFontWeight = FontWeight.w600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gradeLabel.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                gradeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, size: 28, color: headerColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displaySubject,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapterName.isEmpty ? '—' : chapterName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: highlightFontWeight,
                          color: highlightColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 17, color: headerColor),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: highlightFontWeight,
                                color: highlightColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (teacher.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 17, color: headerColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                teacher,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: highlightFontWeight,
                                  color: highlightColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                dayOfWeekName.isNotEmpty
                    ? dayOfWeekName
                    : (day.isNotEmpty ? day : '—'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: highlightFontWeight,
                  color: highlightColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _headerColorForSubject(String subject) {
    final s = subject.toUpperCase();
    if (s.contains('MATH') || s.contains('MATHEMATICS')) return Colors.purple.shade700;
    if (s.contains('SCIENCE')) return Colors.green.shade700;
    return Colors.blue.shade700;
  }

  Color _iconColorForSubject(String subject) {
    final s = subject.toUpperCase();
    if (s.contains('MATH') || s.contains('MATHEMATICS')) return Colors.purple.shade50;
    if (s.contains('SCIENCE')) return Colors.green.shade50;
    return Colors.blue.shade50;
  }

  IconData _iconForSubject(String subject) {
    final s = subject.toUpperCase();
    if (s.contains('ICT') || s.contains('COMPUTER')) return Icons.computer;
    if (s.contains('MATH') || s.contains('MATHEMATICS')) return Icons.calculate;
    if (s.contains('SCIENCE')) return Icons.science;
    return Icons.menu_book;
  }
}
