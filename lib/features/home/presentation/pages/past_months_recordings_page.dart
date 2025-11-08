import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/entities/subject.dart';
import 'view_old_videos_page.dart';
import 'old_videos_bloc.dart';
import '../../../../core/services/master_data_service.dart';

class PastMonthsRecordingsPage extends StatefulWidget {
  const PastMonthsRecordingsPage({super.key});

  @override
  State<PastMonthsRecordingsPage> createState() => _PastMonthsRecordingsPageState();
}

class _PastMonthsRecordingsPageState extends State<PastMonthsRecordingsPage> {
  List<int> _paidMonths = [];
  List<Subject> _subjects = [];
  List<String> _grades = [];
  String? _selectedSubject;
  String? _selectedGrade;
  bool _isLoading = true;
  bool _isLoadingSubjects = true;
  bool _isLoadingGrades = true;
  String? _error;
  String? _subjectsError;
  String? _gradesError;

  @override
  void initState() {
    super.initState();
    _loadGrades();
    _loadSubjects();
    _loadPayments();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoadingGrades = true;
      _gradesError = null;
    });
    
    try {
      // First try to get from teacher master data
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.grades.isNotEmpty) {
        setState(() {
          _grades = masterData.grades;
          _isLoadingGrades = false;
        });
        print('🎥 [DEBUG] PastMonthsRecordingsPage - Loaded ${_grades.length} grades from master data');
        return;
      }
      
      // Fallback to Grade entities from master data
      final gradeEntities = await MasterDataService.getGrades();
      if (gradeEntities.isNotEmpty) {
        setState(() {
          _grades = gradeEntities.map((g) => g.name).toList();
          _isLoadingGrades = false;
        });
        print('🎥 [DEBUG] PastMonthsRecordingsPage - Loaded ${_grades.length} grades from Grade entities');
        return;
      }
      
      // If no grades found, set empty list
      setState(() {
        _grades = [];
        _isLoadingGrades = false;
      });
      print('⚠️ [DEBUG] PastMonthsRecordingsPage - No grades found in master data');
    } catch (e) {
      print('⚠️ [DEBUG] PastMonthsRecordingsPage - Error loading grades: $e');
      setState(() {
        _gradesError = e.toString();
        _grades = [];
        _isLoadingGrades = false;
      });
    }
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
      _subjectsError = null;
    });

    try {
      // First try to get from teacher master data
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.subjects.isNotEmpty) {
        // Convert subject strings to Subject entities
        final subjectEntities = masterData.subjects.map((subjectName) {
          return Subject(
            id: subjectName,
            subject: subjectName,
            teacherId: masterData.teacherId,
          );
        }).toList();
        setState(() {
          _subjects = subjectEntities;
          _isLoadingSubjects = false;
        });
        print('🎥 [DEBUG] PastMonthsRecordingsPage - Loaded ${_subjects.length} subjects from master data');
        return;
      }
      
      // Fallback to Subject entities from master data
      final subjectEntities = await MasterDataService.getSubjects();
      if (subjectEntities.isNotEmpty) {
        setState(() {
          _subjects = subjectEntities;
          _isLoadingSubjects = false;
        });
        print('🎥 [DEBUG] PastMonthsRecordingsPage - Loaded ${_subjects.length} subjects from Subject entities');
        return;
      }
      
      // If no subjects found, set empty list
      setState(() {
        _subjects = [];
        _isLoadingSubjects = false;
      });
      print('⚠️ [DEBUG] PastMonthsRecordingsPage - No subjects found in master data');
    } catch (e) {
      print('⚠️ [DEBUG] PastMonthsRecordingsPage - Error loading subjects: $e');
      setState(() {
        _subjectsError = e.toString();
        _subjects = [];
        _isLoadingSubjects = false;
      });
    }
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
      final teacherId = user.teacherId ?? '';
      final params = GetUserPaymentsParams(
        userId: user.userId,
        teacherId: teacherId.isNotEmpty ? teacherId : null,
      );
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
          // Filter payments for current year with completed/approved status
          // Also filter by selected subject and grade if they are selected
          // Extract grade number from selected grade (e.g., "Grade 1" -> "1")
          final selectedGradeNumber = _selectedGrade != null
              ? _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '')
              : null;
          
          final filteredPayments = payments.where((p) {
            final matchesYear = p.year == currentYear;
            final matchesStatus = p.status == 'approved';
            final matchesSubject = _selectedSubject == null || p.subject == _selectedSubject;
            // Extract grade number from payment grade for comparison
            final paymentGradeNumber = p.grade.replaceAll(RegExp(r'[^0-9]'), '');
            final matchesGrade = selectedGradeNumber == null || paymentGradeNumber == selectedGradeNumber;
            return matchesYear && matchesStatus && matchesSubject && matchesGrade;
          }).toList();
          
          final paidMonths = filteredPayments
              .map((p) => p.month)
              .toSet()
              .toList();

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

  void _handleMonthTap(int month, BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user == null || _selectedGrade == null || _selectedSubject == null) return;

    if (_isMonthPaid(month)) {
      // Navigate to ViewOldVideoPage with grade, month, and subject
      final now = DateTime.now();
      final currentYear = now.year;
      // Extract grade number from "Grade X" format if needed
      String? gradeValue = _selectedGrade;
      if (gradeValue != null && gradeValue.contains('Grade')) {
        gradeValue = gradeValue.replaceAll(RegExp(r'[^0-9]'), '');
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<OldVideosBloc>(),
            child: ViewOldVideoPage(
              grade: gradeValue,
              month: month,
              subject: _selectedSubject,
            ),
          ),
        ),
      );
    } else {
      // Navigate to Payment Page
      final userId = user.userId;
      final teacherId = user.teacherId ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => sl<PaymentBloc>(),
            child: PaymentPage(userId: userId, teacherId: teacherId),
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
        appBar: AppBar(
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
      appBar: AppBar(
        title: const Text('පසුගිය මාසවල රෙකෝඩින්'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading || _isLoadingSubjects
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
                        onPressed: () {
                          _loadPayments();
                          _loadSubjects();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadPayments(),
                      _loadSubjects(),
                    ]);
                  },
                  child: Column(
                    children: [
                      // Grade and Subjects section at the top
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.grey[100],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grade dropdown
                            const Text(
                              'Select Grade:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isLoadingGrades
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Loading grades...', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : _grades.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'No grades available',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : DropdownButtonFormField<String>(
                                        value: _selectedGrade,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        hint: const Text('Select Grade'),
                                        items: _grades.map((grade) {
                                          return DropdownMenuItem<String>(
                                            value: 'Grade $grade',
                                            child: Text('Grade $grade'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGrade = value;
                                            // Clear subject selection when grade changes
                                            _selectedSubject = null;
                                          });
                                          // Reload payments when grade selection changes
                                          _loadPayments();
                                        },
                                      ),
                            const SizedBox(height: 16),
                            // Subjects section
                            if (_subjects.isNotEmpty) ...[
                              const Text(
                                'Select Subject:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _subjects.map((subject) {
                                  final isSelected = _selectedSubject == subject.subject;
                                  return FilterChip(
                                    label: Text(subject.subject),
                                    selected: isSelected,
                                    onSelected: _selectedGrade != null
                                        ? (selected) {
                                            setState(() {
                                              _selectedSubject = selected ? subject.subject : null;
                                            });
                                            // Reload payments when subject selection changes
                                            _loadPayments();
                                          }
                                        : null,
                                    selectedColor: Colors.purple[200],
                                    checkmarkColor: Colors.purple[900],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.purple[900] : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
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

