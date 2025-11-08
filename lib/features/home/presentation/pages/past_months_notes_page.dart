import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/entities/subject.dart';
import '../../../../core/services/master_data_service.dart';
import 'notes_assignments_page.dart';

class PastMonthsNotesPage extends StatefulWidget {
  const PastMonthsNotesPage({super.key});

  @override
  State<PastMonthsNotesPage> createState() => _PastMonthsNotesPageState();
}

class _PastMonthsNotesPageState extends State<PastMonthsNotesPage> {
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
    _loadPayments();
    _loadSubjects();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoadingGrades = true;
      _gradesError = null;
    });
    
    try {
      print('📝 [DEBUG] PastMonthsNotesPage - Starting to load grades from master data');
      
      // First try to get from teacher master data (master_teacher collection)
      final masterData = await MasterDataService.getTeacherMasterData();
      print('📝 [DEBUG] PastMonthsNotesPage - Master data result: ${masterData != null ? "Found" : "Not found"}');
      
      if (masterData != null && masterData.grades.isNotEmpty) {
        print('📝 [DEBUG] PastMonthsNotesPage - Master data grades: ${masterData.grades}');
        
        setState(() {
          _grades = masterData.grades;
          _isLoadingGrades = false;
        });
        print('✅ [DEBUG] PastMonthsNotesPage - Successfully loaded ${_grades.length} grades from master_teacher collection');
        print('✅ [DEBUG] PastMonthsNotesPage - Grades: $_grades');
        return;
      }
      
      // Fallback to Grade entities from master data
      print('📝 [DEBUG] PastMonthsNotesPage - Trying fallback: loading from Grade entities');
      final gradeEntities = await MasterDataService.getGrades();
      print('📝 [DEBUG] PastMonthsNotesPage - Grade entities count: ${gradeEntities.length}');
      
      if (gradeEntities.isNotEmpty) {
        final gradeNames = gradeEntities.map((g) => g.name).toList();
        print('📝 [DEBUG] PastMonthsNotesPage - Grade entity names: $gradeNames');
        
        setState(() {
          _grades = gradeNames;
          _isLoadingGrades = false;
        });
        print('⚠️ [DEBUG] PastMonthsNotesPage - Loaded ${_grades.length} grades from Grade entities (fallback)');
        print('⚠️ [DEBUG] PastMonthsNotesPage - Grades: $_grades');
        print('⚠️ [WARNING] PastMonthsNotesPage - Using fallback grades collection instead of master_teacher!');
        return;
      }
      
      // If no grades found, set empty list
      setState(() {
        _grades = [];
        _isLoadingGrades = false;
      });
      print('❌ [DEBUG] PastMonthsNotesPage - No grades found in master data');
    } catch (e) {
      print('❌ [DEBUG] PastMonthsNotesPage - Error loading grades: $e');
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
      print('📝 [DEBUG] PastMonthsNotesPage - Starting to load subjects from master data');
      
      // First try to get from teacher master data (master_teacher collection)
      final masterData = await MasterDataService.getTeacherMasterData();
      print('📝 [DEBUG] PastMonthsNotesPage - Master data result: ${masterData != null ? "Found" : "Not found"}');
      
      if (masterData != null && masterData.subjects.isNotEmpty) {
        print('📝 [DEBUG] PastMonthsNotesPage - Master data subjects: ${masterData.subjects}');
        
        // Convert subject strings to Subject entities
        final subjects = masterData.subjects.map((subjectName) {
          return Subject(
            id: subjectName,
            subject: subjectName,
            teacherId: masterData.teacherId,
          );
        }).toList();
        
        setState(() {
          _subjects = subjects;
          _isLoadingSubjects = false;
        });
        print('✅ [DEBUG] PastMonthsNotesPage - Successfully loaded ${_subjects.length} subjects from master_teacher collection');
        return;
      }
      
      // Fallback to Subject entities from master data
      print('📝 [DEBUG] PastMonthsNotesPage - Trying fallback: loading from Subject entities');
      final subjectEntities = await MasterDataService.getSubjects();
      print('📝 [DEBUG] PastMonthsNotesPage - Subject entities count: ${subjectEntities.length}');
      
      if (subjectEntities.isNotEmpty) {
        setState(() {
          _subjects = subjectEntities;
          _isLoadingSubjects = false;
        });
        print('⚠️ [DEBUG] PastMonthsNotesPage - Loaded ${_subjects.length} subjects from Subject entities (fallback)');
        print('⚠️ [WARNING] PastMonthsNotesPage - Using fallback subjects collection instead of master_teacher!');
        return;
      }
      
      // If no subjects found, set empty list
      setState(() {
        _subjects = [];
        _isLoadingSubjects = false;
      });
      print('❌ [DEBUG] PastMonthsNotesPage - No subjects found in master data');
    } catch (e) {
      print('❌ [DEBUG] PastMonthsNotesPage - Error loading subjects: $e');
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
      // Navigate to NotesAssignmentsPage with grade and month
      // Extract grade number from "Grade X" format if needed
      String? gradeValue = _selectedGrade;
      if (gradeValue != null && gradeValue.contains('Grade')) {
        gradeValue = gradeValue.replaceAll(RegExp(r'[^0-9]'), '');
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotesAssignmentsPage(
            initialGrade: gradeValue,
            initialMonth: month,
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
      appBar: AppBar(
        title: const Text('පසුගිය මාසවල නිබන්ධන'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading || _isLoadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _subjectsError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${_error ?? _subjectsError}',
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
                            DropdownButtonFormField<String>(
                              value: _selectedGrade,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                errorText: _gradesError != null ? _gradesError : null,
                              ),
                              hint: const Text('Select Grade'),
                              items: _isLoadingGrades
                                  ? [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Loading grades...'),
                                      )
                                    ]
                                  : _grades.isEmpty
                                      ? [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('No grades available'),
                                          )
                                        ]
                                      : _grades.map((grade) {
                                          final gradeValue = grade.contains('Grade') ? grade : 'Grade $grade';
                                          return DropdownMenuItem<String>(
                                            value: gradeValue,
                                            child: Text(gradeValue),
                                          );
                                        }).toList(),
                              onChanged: _isLoadingGrades || _grades.isEmpty
                                  ? null
                                  : (value) {
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
                                    selectedColor: Colors.orange[200],
                                    checkmarkColor: Colors.orange[900],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.orange[900] : Colors.black87,
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
                                                  isPaid ? Icons.note : Icons.payment,
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

