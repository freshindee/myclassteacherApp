import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import 'view_old_videos_page.dart';

class PastMonthsRecordingsPage extends StatefulWidget {
  const PastMonthsRecordingsPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<PastMonthsRecordingsPage> createState() => _PastMonthsRecordingsPageState();
}

class _PastMonthsRecordingsPageState extends State<PastMonthsRecordingsPage> {
  List<int> _paidMonths = [];
  String? _selectedSubject;
  String? _selectedGrade;
  String? _selectedClassName;
  Map<String, dynamic>? _selectedClassDoc;
  List<Map<String, dynamic>> _classesForGrade = [];
  bool _loadingClasses = false;
  List<Map<String, dynamic>> _classSubjectsForSelectedClass = [];
  bool _loadingClassSubjects = false;
  Map<String, String> _subjectIdToName = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  String _subjectDisplayName(Map<String, dynamic> classSubjectItem) {
    final subjectId = classSubjectItem['subject_id']?.toString() ??
        classSubjectItem['subjectId']?.toString() ??
        classSubjectItem['subject']?.toString();
    if (subjectId == null || subjectId.isEmpty) return '—';
    return _subjectIdToName[subjectId] ?? '—';
  }

  static bool _isPaidStatus(String status) {
    final s = status.toLowerCase();
    return s == 'paid' || s == 'approved' || s == 'completed';
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;

      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final getUserPayments = sl<GetUserPayments>();
      final schoolId = user.teacherId ?? '';
      // Pass schoolId so we query schools/{schoolId}/payments by student_id (all payment records for this student)
      final params = GetUserPaymentsParams(userId: user.userId, schoolId: schoolId);
      final result = await getUserPayments(params);

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (payments) {
          final currentYear = DateTime.now().year;
          final selectedGradeNumber = _selectedGrade != null && _selectedGrade!.isNotEmpty
              ? _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '')
              : null;

          // Consider paid/approved/completed; filter by current year and selected subject/grade
          final filteredPayments = payments.where((p) {
            final matchesYear = p.year == currentYear;
            final matchesStatus = _isPaidStatus(p.status);
            final matchesSubject = _selectedSubject == null || p.subject == _selectedSubject;
            final paymentGradeNumber = p.grade.replaceAll(RegExp(r'[^0-9]'), '');
            final matchesGrade = selectedGradeNumber == null || paymentGradeNumber == selectedGradeNumber;
            return matchesYear && matchesStatus && matchesSubject && matchesGrade;
          }).toList();

          final paidMonths = filteredPayments.map((p) => p.month).toSet().toList();

          setState(() {
            _paidMonths = paidMonths;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<int> _getMonthsList() {
    final now = DateTime.now();
    final currentMonth = now.month;
    // Generate list from current month down to January (reverse order)
    return List.generate(currentMonth, (index) => currentMonth - index);
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  bool _isMonthPaid(int month) {
    return _paidMonths.contains(month);
  }

  String? _getSelectedClassSubjectId() {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) return null;
    for (final item in _classSubjectsForSelectedClass) {
      if (_subjectDisplayName(item) == _selectedSubject) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
        return null;
      }
    }
    return null;
  }

  void _handleMonthTap(int month, BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user == null || _selectedGrade == null || _selectedSubject == null) return;

    if (_isMonthPaid(month)) {
      final gradeValue = _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
          ? _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '')
          : _selectedGrade!;
      final classSubjectId = _getSelectedClassSubjectId();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewOldVideoPage(
            grade: gradeValue,
            month: month,
            subject: _selectedSubject,
            classSubjectId: classSubjectId,
          ),
        ),
      );
    } else {
      // Navigate to Payment Page
      final userId = user.userId;
      final schoolId = user.teacherId ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<PaymentBloc>(),
            child: PaymentPage(
              userId: userId,
              schoolId: schoolId,
              embedInHomeShell: widget.embedInHomeShell,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: widget.embedInHomeShell
            ? null
            : AppBar(
                title: const Text('පසුගිය මාසවල රෙකෝඩින්'),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
        body: const Center(
          child: Text('Please login to view past months recordings'),
        ),
      );
    }

    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text('පසුගිය මාසවල රෙකෝඩින්'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GradeSelector(
                                value: _selectedGrade,
                                label: 'පන්තිය',
                                hint: 'පන්තිය තෝරන්න',
                                onGradeSelected: (value) async {
                                  setState(() {
                                    _selectedGrade = value;
                                    _selectedClassName = null;
                                    _selectedClassDoc = null;
                                    _selectedSubject = null;
                                    _classesForGrade = [];
                                    _classSubjectsForSelectedClass = [];
                                    _subjectIdToName = {};
                                  });
                                  if (value != null && value.isNotEmpty) {
                                    final schoolId = user!.teacherId ?? '';
                                    if (schoolId.isEmpty) {
                                      _loadPayments();
                                      return;
                                    }
                                    setState(() => _loadingClasses = true);
                                    final cache = sl<SchoolCacheService>();
                                    final list = await cache.getClassesByGradeNumber(schoolId, value);
                                    if (mounted) {
                                      setState(() {
                                        _classesForGrade = list;
                                        _loadingClasses = false;
                                        if (list.length == 1) {
                                          _selectedClassDoc = list.first;
                                          _selectedClassName = SchoolCacheService.classDisplayName(list.first, value);
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
                                      _loadPayments();
                                    }
                                  } else {
                                    _loadPayments();
                                  }
                                },
                              ),
                              if (_selectedGrade != null && _selectedGrade!.isNotEmpty) ...[
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
                                    value: _selectedClassName != null &&
                                            _classesForGrade.any((c) =>
                                                SchoolCacheService.classDisplayName(c, _selectedGrade!) == _selectedClassName)
                                        ? _selectedClassName
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'පන්තියේ නම',
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text('පන්තිය තෝරන්න'),
                                    items: _classesForGrade.map((c) {
                                      final name = SchoolCacheService.classDisplayName(c, _selectedGrade!);
                                      return DropdownMenuItem<String>(value: name, child: Text(name));
                                    }).toList(),
                                    onChanged: (value) async {
                                      final className = value ?? '';
                                      final schoolId = user!.teacherId ?? '';
                                      final doc = _classesForGrade.cast<Map<String, dynamic>>().firstWhere(
                                            (c) => SchoolCacheService.classDisplayName(c, _selectedGrade!) == className,
                                            orElse: () => <String, dynamic>{},
                                          );
                                      setState(() {
                                        _selectedClassName = className;
                                        _selectedClassDoc = doc.isNotEmpty ? doc : null;
                                        _selectedSubject = null;
                                        _classSubjectsForSelectedClass = [];
                                        _subjectIdToName = {};
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
                                          _loadPayments();
                                        }
                                      } else {
                                        _loadPayments();
                                      }
                                    },
                                  ),
                                const SizedBox(height: 12),
                              ],
                              if (_selectedClassDoc != null && _selectedClassName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'විෂය තෝරන්න',
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
                                      final isSelected = _selectedSubject == name;
                                      return FilterChip(
                                        label: Text(name),
                                        selected: isSelected,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedSubject = isSelected ? null : name;
                                          });
                                          _loadPayments();
                                        },
                                        selectedColor: Colors.purple[200],
                                        checkmarkColor: Colors.purple[900],
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.purple[900] : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Months list - only show when both grade and subject are selected
                      Expanded(
                        child: _selectedGrade == null || _selectedSubject == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedGrade == null ? Icons.school : Icons.subject,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _selectedGrade == null
                                          ? 'Please select a grade to view months'
                                          : 'Please select a subject to view months',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _getMonthsList().length,
                                itemBuilder: (context, index) {
                                  final month = _getMonthsList()[index];
                                  final monthName = _getMonthName(month);
                                  final isPaid = _isMonthPaid(month);
                                  final currentYear = DateTime.now().year;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () => _handleMonthTap(month, context),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: isPaid ? Colors.green : Colors.orange,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  month.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    monthName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$currentYear',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  isPaid ? Icons.play_circle : Icons.payment,
                                                  color: isPaid ? Colors.green : Colors.orange,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  isPaid ? 'Watch videos' : 'Pay & watch video',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isPaid ? Colors.green : Colors.orange,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

