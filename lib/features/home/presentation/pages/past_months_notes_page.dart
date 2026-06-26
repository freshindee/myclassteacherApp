import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/grade_selector.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/entities/payment.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import 'past_month_notes_list_page.dart';

class PastMonthsNotesPage extends StatefulWidget {
  const PastMonthsNotesPage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<PastMonthsNotesPage> createState() => _PastMonthsNotesPageState();
}

class _PastMonthsNotesPageState extends State<PastMonthsNotesPage> {
  List<int> _paidMonths = [];
  List<dynamic> currentMonthPayments = [];
  bool paymentsLoaded = false;
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

  static bool _isPaidStatus(String status) {
    final s = status.toLowerCase();
    return s == 'paid' || s == 'approved' || s == 'completed';
  }

  bool _hasPaymentForSelection() {
    if (!paymentsLoaded || _selectedGrade == null || _selectedSubject == null) return false;
    final now = DateTime.now();
    final grade = _selectedGrade!;
    final subject = _selectedSubject!;
    final classSubjectId = _getSelectedClassSubjectId();
    for (final p in currentMonthPayments) {
      if (p is! Payment) continue;
      if (p.month != now.month || p.year != now.year) continue;
      if (!_isPaidStatus(p.status)) continue;
      if (classSubjectId != null && p.classSubjectId != null && p.classSubjectId == classSubjectId) return true;
      if (p.grade == grade && p.subject == subject) return true;
    }
    return false;
  }

  Set<String> _allowedClassSubjectIds() {
    final allowed = <String>{};
    for (final doc in _classSubjectsForSelectedClass) {
      if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
        if (_subjectDisplayName(doc) != _selectedSubject) continue;
      }
      final id = doc['id']?.toString();
      if (id != null && id.isNotEmpty) allowed.add(id);
    }
    return allowed;
  }

  bool _isFreeAndForSelectedClass(Map<String, dynamic> item, Set<String> allowedIds) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access.isNotEmpty && access != 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
  }

  bool _isPaidAndForSelectedClass(Map<String, dynamic> item, Set<String> allowedIds) {
    final access = (item['accessLevel'] ?? item['access_level'] ?? '').toString().trim().toLowerCase();
    if (access == 'free') return false;
    final csId = item['class_subject_id']?.toString()?.trim();
    if (csId == null || csId.isEmpty) return false;
    return allowedIds.contains(csId);
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
      final params = GetUserPaymentsParams(userId: user.userId, schoolId: schoolId);
      final result = await getUserPayments(params);

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
            paymentsLoaded = false;
          });
        },
        (payments) {
          final now = DateTime.now();
          final currentYear = now.year;
          final currentMonth = now.month;
          final selectedGradeNumber = _selectedGrade != null && _selectedGrade!.isNotEmpty
              ? _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '')
              : null;

          final currentMonthList = payments.where((p) {
            if (p.month != currentMonth || p.year != currentYear) return false;
            return _isPaidStatus(p.status);
          }).toList();

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
            currentMonthPayments = currentMonthList;
            paymentsLoaded = true;
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

  void _handleMonthTap(int month, BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user == null || _selectedGrade == null || _selectedSubject == null) return;

    final schoolId = user.teacherId ?? '';
    if (schoolId.isEmpty) return;

    if (_isMonthPaid(month)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PastMonthNotesListPage(
            schoolId: schoolId,
            grade: _selectedGrade!,
            month: month,
            subject: _selectedSubject!,
            classSubjectsForSelectedClass: _classSubjectsForSelectedClass,
            subjectIdToName: _subjectIdToName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<PaymentBloc>(),
            child: PaymentPage(
              userId: user.userId,
              schoolId: schoolId,
              embedInHomeShell: widget.embedInHomeShell,
            ),
          ),
        ),
      );
    }
  }

  /// Loads PDF notes from local DB (school_content_pdf_notes, same as FreeVideosPage Notes tab). Shows free + paid when has payment.
  Widget _buildNotesFromCache(BuildContext context, String schoolId) {
    final allowedIds = _allowedClassSubjectIds();
    final hasPayment = _hasPaymentForSelection();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sl<SchoolCacheService>().getSchoolContentPdfNotes(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final freeList = all.where((item) => _isFreeAndForSelectedClass(item, allowedIds)).toList();
        final paidList = hasPayment
            ? all.where((item) => _isPaidAndForSelectedClass(item, allowedIds)).toList()
            : <Map<String, dynamic>>[];
        final combined = [...freeList, ...paidList];
        if (combined.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notes for this class/subject'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combined.length,
          itemBuilder: (context, index) {
            final note = combined[index];
            final isFree = _isFreeAndForSelectedClass(note, allowedIds);
            return _buildNoteListItem(context, note, isFree: isFree);
          },
        );
      },
    );
  }

  /// Same notes cell design as FreeVideosPage: card with Grade pill, title, description, View & Download buttons.
  /// Uses pdf_notes DB: title, description, pdf_url, grade. Optional Free/Paid badge for PastMonthsNotesPage.
  Widget _buildNoteListItem(BuildContext context, Map<String, dynamic> note, {bool isFree = true}) {
    final title = note['title']?.toString().trim() ?? 'Note';
    final description = note['description']?.toString().trim() ?? '';
    final pdfUrl = (note['pdf_url'] ?? note['file_url'])?.toString().trim() ?? '';
    final grade = note['grade']?.toString().trim();
    final gradeNum = grade?.replaceAll(RegExp(r'[^0-9]'), '')?.trim() ?? '';
    final displayGradeLabel = gradeNum.isNotEmpty
        ? 'Grade: $gradeNum'
        : (grade?.isNotEmpty == true ? 'Grade: ${grade!.replaceFirst(RegExp(r'^Grade\s*', caseSensitive: false), '').trim()}' : '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (displayGradeLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayGradeLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFree ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFree ? 'Free' : 'Paid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFree ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (displayGradeLabel.isNotEmpty) const SizedBox(height: 10),
            if (displayGradeLabel.isEmpty) const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pdfUrl.isNotEmpty) {
                        launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pdfUrl.isNotEmpty) {
                        launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                title: const Text('පසුගිය මාසවල නිබන්ධන'),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
        body: const Center(
          child: Text('Please login to view past months notes'),
        ),
      );
    }

    return Scaffold(
      appBar: widget.embedInHomeShell
          ? null
          : AppBar(
              title: const Text('පසුගිය මාසවල නිබන්ධන'),
              backgroundColor: Colors.orange,
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
                                        selectedColor: Colors.orange[200],
                                        checkmarkColor: Colors.orange[900],
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.orange[900] : Colors.black87,
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
                      // Month list (same as PastMonthsRecordingsPage) - show after grade + subject selected
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
                            : (!paymentsLoaded)
                                ? const Center(child: Text('Loading your payment data...'))
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
                                                      isPaid ? Icons.description : Icons.payment,
                                                      color: isPaid ? Colors.green : Colors.orange,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      isPaid ? 'View notes' : 'Pay & view notes',
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

