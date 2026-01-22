import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/today_class.dart';
import 'today_classes_bloc.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/master_data_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';

class TodayClassesPage extends StatefulWidget {
  const TodayClassesPage({super.key});

  @override
  State<TodayClassesPage> createState() => _TodayClassesPageState();
}

class _TodayClassesPageState extends State<TodayClassesPage> {
  String? selectedGrade;
  String? selectedSubject;
  List<String> grades = [];
  List<String> subjects = [];
  bool _isLoadingGrades = true;
  bool _isLoadingSubjects = true;

  List<dynamic> currentMonthPayments = [];
  bool paymentsLoading = false;
  bool paymentsLoaded = false;
  String? paymentsError;

  @override
  void initState() {
    super.initState();
    _loadGrades();
    _loadSubjects();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoadingGrades = true;
    });
    
    try {
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.grades.isNotEmpty) {
        setState(() {
          grades = masterData.grades;
          _isLoadingGrades = false;
        });
        return;
      }
      
      final gradeEntities = await MasterDataService.getGrades();
      if (gradeEntities.isNotEmpty) {
        setState(() {
          grades = gradeEntities.map((g) => g.name).toList();
          _isLoadingGrades = false;
        });
        return;
      }
      
      setState(() {
        grades = [];
        _isLoadingGrades = false;
      });
    } catch (e) {
      setState(() {
        grades = [];
        _isLoadingGrades = false;
      });
    }
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });
    
    try {
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.subjects.isNotEmpty) {
        setState(() {
          subjects = masterData.subjects;
          _isLoadingSubjects = false;
        });
        return;
      }
      
      final subjectEntities = await MasterDataService.getSubjects();
      if (subjectEntities.isNotEmpty) {
        setState(() {
          subjects = subjectEntities.map((s) => s.subject).toList();
          _isLoadingSubjects = false;
        });
        return;
      }
      
      setState(() {
        subjects = [];
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        subjects = [];
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _fetchPayments() async {
    setState(() {
      paymentsLoading = true;
      paymentsError = null;
    });
    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;
      if (user == null) return;
      final userId = user.userId;
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      final getUserPayments = sl<GetUserPayments>();
      final params = GetUserPaymentsParams(userId: userId);
      final result = await getUserPayments(params);
      result.fold(
        (failure) {
          setState(() {
            paymentsError = failure.message;
            paymentsLoading = false;
            paymentsLoaded = false;
          });
        },
        (payments) {
          final filtered = payments.where((p) => p.month == currentMonth && p.year == currentYear && p.status == 'approved').toList();
          setState(() {
            currentMonthPayments = filtered;
            paymentsLoading = false;
            paymentsLoaded = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        paymentsError = e.toString();
        paymentsLoading = false;
        paymentsLoaded = false;
      });
    }
  }

  void _onGradeOrSubjectChanged(String? grade, String? subject, String userId, String teacherId, BuildContext context) {
    setState(() {
      selectedGrade = grade;
      selectedSubject = subject;
    });
    if (grade != null && subject != null && paymentsLoaded) {
      final hasPayment = currentMonthPayments.any((p) => p.grade == grade && p.subject == subject);
      if (!hasPayment) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ඔබ පන්ති ගාස්තු ගෙවා නැත'),
            content: Text('ඔබ මෙම මාසයට Grade $grade - $subject සඳහා පන්ති ගාස්තු ගෙවා නැත.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      // Format grade to match Firestore format: "Grade 7" instead of "7"
      final formattedGrade = 'Grade $grade';
      context.read<TodayClassesBloc>().add(LoadTodayClasses(teacherId, grade: formattedGrade, subject: subject));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("අද දවසේ පන්ති"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view today classes'),
        ),
      );
    }

    final userId = user.userId;
    final teacherId = user.teacherId ?? '';

    return BlocProvider(
      create: (context) => sl<TodayClassesBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("අද දවසේ පන්ති"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            if (paymentsLoading)
              const LinearProgressIndicator(),
            if (paymentsError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading payments: $paymentsError', style: const TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('පන්තිය තෝරන්න : ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingGrades
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
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
                            : grades.isEmpty
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
                                    value: selectedGrade,
                                    hint: const Text('All'),
                                    isExpanded: true,
                                    items: grades.map((grade) {
                                      return DropdownMenuItem(
                                        value: grade,
                                        child: Text('Grade $grade'),
                                      );
                                    }).toList(),
                                    onChanged: (grade) {
                                      _onGradeOrSubjectChanged(grade, selectedSubject, userId, teacherId, context);
                                    },
                                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('විෂයය තෝරන්න : ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingSubjects
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Loading subjects...', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : subjects.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'No subjects available',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : DropdownButton<String>(
                                    value: selectedSubject,
                                    hint: const Text('All'),
                                    isExpanded: true,
                                    items: subjects.map((subject) {
                                      return DropdownMenuItem(
                                        value: subject,
                                        child: Text(subject),
                                      );
                                    }).toList(),
                                    onChanged: (subject) {
                                      _onGradeOrSubjectChanged(selectedGrade, subject, userId, teacherId, context);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: (!paymentsLoaded)
                  ? const Center(child: Text('Loading your payment data...'))
                  : (selectedGrade == null || selectedSubject == null)
                      ? const Center(child: Text('පන්ති නැරබීමට පන්තිය සහ විෂයය තෝරන්න'))
                      : BlocBuilder<TodayClassesBloc, TodayClassesState>(
                          builder: (context, state) {
                            if (state is TodayClassesLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (state is TodayClassesLoaded) {
                              return _buildClassList(context, state.classes);
                            } else if (state is TodayClassesError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Error: ${state.message}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        final formattedGrade = 'Grade $selectedGrade';
                                        context.read<TodayClassesBloc>().add(
                                          LoadTodayClasses(teacherId, grade: formattedGrade, subject: selectedSubject),
                                        );
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const Center(child: Text('අද දින පන්ති නොමැත.'));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassList(BuildContext context, List<TodayClass> classes) {
    if (classes.isEmpty) {
      return const Center(child: Text('අද දින පන්ති නොමැත..'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final todayClass = classes[index];
        return _buildClassCard(context, todayClass);
      },
    );
  }

  Widget _buildClassCard(BuildContext context, TodayClass todayClass) {
    String? teacherImage;
    switch (todayClass.teacherId) {
      case 1:
        teacherImage = 'assets/images/aruna2.jpeg';
        break;
      case 6:
        teacherImage = 'assets/images/samu2.jpeg';
        break;
      case 4:
        teacherImage = 'assets/images/mahesh.jpeg';
        break;
      case 2:
        teacherImage = 'assets/images/sajith.jpeg';
        break;
      case 5:
        teacherImage = 'assets/images/indika.png';
        break;
      case 3:
        teacherImage = 'assets/images/mana.jpeg';
        break;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teacherImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  teacherImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            if (teacherImage != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayClass.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayClass.grade,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teacher: ${todayClass.teacher}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${todayClass.time}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // Zoom class ID - always display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.video_call, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Zoom class ID: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            (todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty) 
                                ? todayClass.zoomId! 
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty)
                                  ? Colors.blue.shade900
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Password - always display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Password: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            (todayClass.password != null && todayClass.password!.isNotEmpty) 
                                ? todayClass.password! 
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (todayClass.password != null && todayClass.password!.isNotEmpty)
                                  ? Colors.orange.shade900
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _shareLink(context, todayClass),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _joinNow(context, todayClass.joinUrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Join Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _shareLink(BuildContext context, TodayClass todayClass) async {
    try {
      // Build share text with class details
      final shareText = '''
${todayClass.subject} - ${todayClass.grade}
Teacher: ${todayClass.teacher}
Time: ${todayClass.time}
${todayClass.zoomId != null && todayClass.zoomId!.isNotEmpty ? 'Zoom ID: ${todayClass.zoomId}' : ''}
${todayClass.password != null && todayClass.password!.isNotEmpty ? 'Password: ${todayClass.password}' : ''}

Join Link: ${todayClass.joinUrl}
''';
      
      await Share.share(
        shareText,
        subject: '${todayClass.subject} Class - ${todayClass.grade}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinNow(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not join class'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 