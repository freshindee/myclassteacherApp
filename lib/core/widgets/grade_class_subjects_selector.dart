import 'package:flutter/material.dart';
import '../services/school_cache_service.dart';
import '../../injection_container.dart';

/// Reusable control: select a grade, then displays class_subjects for that grade.
/// Data from school cache: schools/{schoolId}/class_subjects (filtered by grade).
///
/// Use in any screen:
/// ```dart
/// GradeClassSubjectsSelector(
///   schoolId: schoolId,
///   onGradeSelected: (grade) => ...,
///   onClassSubjectSelected: (item) => ...,
/// )
/// ```
class GradeClassSubjectsSelector extends StatefulWidget {
  /// Required school ID (from UserSessionService.getSchoolId()).
  final String schoolId;

  /// Initial grade to select (e.g. pre-filled from parent).
  final String? initialGrade;

  /// When set, grade dropdown is hidden and this grade is used to load class subjects
  /// (e.g. when parent uses [GradeSelector] and passes its value here).
  final String? externalGrade;

  /// Called when the user selects a grade (only when [externalGrade] is null).
  final void Function(String? grade)? onGradeSelected;

  /// Called when the user taps a class_subject item (optional).
  final void Function(Map<String, dynamic> item)? onClassSubjectSelected;

  /// If true, show a compact dropdown + list; if false, show with more spacing.
  final bool compact;

  /// Optional label for the grade dropdown.
  final String gradeLabel;

  /// Optional label for the class subjects section.
  final String classSubjectsLabel;

  const GradeClassSubjectsSelector({
    super.key,
    required this.schoolId,
    this.initialGrade,
    this.externalGrade,
    this.onGradeSelected,
    this.onClassSubjectSelected,
    this.compact = false,
    this.gradeLabel = 'Grade',
    this.classSubjectsLabel = 'Class subjects',
  });

  @override
  State<GradeClassSubjectsSelector> createState() =>
      _GradeClassSubjectsSelectorState();
}

class _GradeClassSubjectsSelectorState extends State<GradeClassSubjectsSelector> {
  final SchoolCacheService _cache = sl<SchoolCacheService>();

  List<String> _grades = [];
  List<Map<String, dynamic>> _classSubjects = [];
  String? _selectedGrade;
  bool _gradesLoading = true;
  bool _subjectsLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.externalGrade ?? widget.initialGrade;
    if (widget.externalGrade != null && widget.externalGrade!.isNotEmpty) {
      _gradesLoading = false;
      _grades = [];
      _loadClassSubjects(widget.externalGrade!);
    } else {
      _loadGrades();
      if (widget.initialGrade != null && widget.initialGrade!.isNotEmpty) {
        _loadClassSubjects(widget.initialGrade!);
      }
    }
  }

  @override
  void didUpdateWidget(GradeClassSubjectsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalGrade != oldWidget.externalGrade) {
      _selectedGrade = widget.externalGrade;
      if (widget.externalGrade != null && widget.externalGrade!.isNotEmpty) {
        _loadClassSubjects(widget.externalGrade!);
      } else {
        setState(() => _classSubjects = []);
      }
    }
  }

  Future<void> _loadGrades() async {
    if (widget.schoolId.isEmpty) {
      setState(() {
        _grades = [];
        _gradesLoading = false;
        _error = 'School ID is required';
      });
      return;
    }
    setState(() {
      _gradesLoading = true;
      _error = null;
    });
    try {
      final grades =
          await _cache.getGradesFromClassSubjects(widget.schoolId);
      setState(() {
        _grades = grades;
        _gradesLoading = false;
        if (_selectedGrade != null &&
            !_grades.contains(_selectedGrade) &&
            _grades.isNotEmpty) {
          _selectedGrade = null;
        }
      });
    } catch (e) {
      setState(() {
        _grades = [];
        _gradesLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadClassSubjects(String grade) async {
    setState(() {
      _subjectsLoading = true;
      _classSubjects = [];
      _error = null;
    });
    try {
      final list = await _cache.getClassSubjectsByGrade(widget.schoolId, grade);
      setState(() {
        _classSubjects = list;
        _subjectsLoading = false;
      });
      widget.onGradeSelected?.call(grade);
    } catch (e) {
      setState(() {
        _classSubjects = [];
        _subjectsLoading = false;
        _error = e.toString();
      });
    }
  }

  String _itemTitle(Map<String, dynamic> item) {
    return item['subject']?.toString() ??
        item['name']?.toString() ??
        item['title']?.toString() ??
        item['id']?.toString() ??
        '—';
  }

  String? _itemSubtitle(Map<String, dynamic> item) {
    final sub = item['description'] ?? item['code'];
    return sub?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? 8.0 : 16.0;

    final useExternalGrade = widget.externalGrade != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grade dropdown (hidden when externalGrade is set)
        if (!useExternalGrade)
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.gradeLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 6),
                if (_gradesLoading)
                  const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_grades.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error ?? 'No grades found. Sync school data first.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select grade'),
                    items: _grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedGrade = value);
                      if (value != null && value.isNotEmpty) {
                        _loadClassSubjects(value);
                      } else {
                        setState(() => _classSubjects = []);
                      }
                      widget.onGradeSelected?.call(value);
                    },
                  ),
              ],
            ),
          ),
        // Class subjects list
        if (_selectedGrade != null && _selectedGrade!.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 6),
            child: Text(
              widget.classSubjectsLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          if (_subjectsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_classSubjects.isEmpty)
            Padding(
              padding: EdgeInsets.all(padding),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No class subjects for this grade.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: padding),
              itemCount: _classSubjects.length,
              separatorBuilder: (_, __) => SizedBox(height: widget.compact ? 4 : 8),
              itemBuilder: (context, index) {
                final item = _classSubjects[index];
                final title = _itemTitle(item);
                final subtitle = _itemSubtitle(item);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onClassSubjectSelected?.call(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: widget.compact ? 10 : 14,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: widget.compact ? 20 : 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: widget.compact ? 14 : 16,
                                  ),
                                ),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.onClassSubjectSelected != null)
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
