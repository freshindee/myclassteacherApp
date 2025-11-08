import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/timetable.dart';
import 'schedule_bloc.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/master_data_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<String> _grades = [];
  bool _isLoadingGrades = true;
  String? _teacherId;
  String? _selectedGrade;
  bool _showTimetable = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _loadGrades();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      _teacherId = user?.teacherId ?? '';
    });
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoadingGrades = true;
    });
    
    try {
      print('📅 [DEBUG] SchedulePage - Starting to load grades from master data');
      
      // First try to get from teacher master data (master_teacher collection)
      final masterData = await MasterDataService.getTeacherMasterData();
      print('📅 [DEBUG] SchedulePage - Master data result: ${masterData != null ? "Found" : "Not found"}');
      
      if (masterData != null) {
        print('📅 [DEBUG] SchedulePage - Master data teacherId: ${masterData.teacherId}');
        print('📅 [DEBUG] SchedulePage - Master data grades count: ${masterData.grades.length}');
        print('📅 [DEBUG] SchedulePage - Master data grades: ${masterData.grades}');
        
        if (masterData.grades.isNotEmpty) {
          setState(() {
            _grades = masterData.grades;
            _isLoadingGrades = false;
          });
          print('✅ [DEBUG] SchedulePage - Successfully loaded ${_grades.length} grades from master_teacher collection');
          print('✅ [DEBUG] SchedulePage - Grades: $_grades');
          return;
        } else {
          print('⚠️ [DEBUG] SchedulePage - Master data found but grades list is empty');
        }
      } else {
        print('⚠️ [DEBUG] SchedulePage - No master data found, will try fallback');
      }
      
      // Fallback to Grade entities from master data (grades collection)
      print('📅 [DEBUG] SchedulePage - Trying fallback: loading from Grade entities');
      final gradeEntities = await MasterDataService.getGrades();
      print('📅 [DEBUG] SchedulePage - Grade entities count: ${gradeEntities.length}');
      
      if (gradeEntities.isNotEmpty) {
        final gradeNames = gradeEntities.map((g) => g.name).toList();
        print('📅 [DEBUG] SchedulePage - Grade entity names: $gradeNames');
        
        setState(() {
          _grades = gradeNames;
          _isLoadingGrades = false;
        });
        print('⚠️ [DEBUG] SchedulePage - Loaded ${_grades.length} grades from Grade entities (fallback)');
        print('⚠️ [DEBUG] SchedulePage - Grades: $_grades');
        print('⚠️ [WARNING] SchedulePage - Using fallback grades collection instead of master_teacher!');
        return;
      }
      
      // If no grades found, set empty list
      setState(() {
        _grades = [];
        _isLoadingGrades = false;
      });
      print('❌ [DEBUG] SchedulePage - No grades found in master data');
    } catch (e) {
      print('❌ [DEBUG] SchedulePage - Error loading grades: $e');
      print('❌ [DEBUG] SchedulePage - Stack trace: ${StackTrace.current}');
      setState(() {
        _grades = [];
        _isLoadingGrades = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_teacherId == null || _isLoadingGrades) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_teacherId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Teacher ID not found. Please login again.'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => sl<ScheduleBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: _showTimetable && _selectedGrade != null
            ? BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  if (state is ScheduleLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading timetable...'),
                        ],
                      ),
                    );
                  } else if (state is TimetableLoaded) {
                    return _buildTimetableView(
                      context,
                      state.timetables,
                      state.selectedGrade,
                      _teacherId!,
                      onBackToGrades: () {
                        setState(() {
                          _showTimetable = false;
                          _selectedGrade = null;
                        });
                      },
                    );
                  } else if (state is ScheduleError) {
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
                              context.read<ScheduleBloc>().add(LoadTimetable(_teacherId!, _selectedGrade!));
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
                        Icon(Icons.schedule, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No timetable available'),
                      ],
                    ),
                  );
                },
              )
            : _buildGradesList(context, _grades, _teacherId!),
        floatingActionButton: _showTimetable
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showTimetable = false;
                    _selectedGrade = null;
                  });
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.list),
              )
            : null,
      ),
    );
  }

  Widget _buildGradesList(BuildContext context, List<String> grades, String teacherId) {
    if (grades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No grades available'),
          ],
        ),
      );
    }

    // Sort grades so that 'Grade 1 to 5' is first, then others numerically
    final sortedGrades = List<String>.from(grades);
    sortedGrades.sort((a, b) {
      // Handle "1 to 5" special case
      if (a.toLowerCase().contains('1 to 5')) return -1;
      if (b.toLowerCase().contains('1 to 5')) return 1;
      
      // Extract numeric value from grade string (handles both "10" and "Grade 10")
      final aClean = a.replaceAll(RegExp(r'[^0-9]'), '');
      final bClean = b.replaceAll(RegExp(r'[^0-9]'), '');
      final aInt = int.tryParse(aClean) ?? 0;
      final bInt = int.tryParse(bClean) ?? 0;
      return aInt.compareTo(bInt);
    });

    return RefreshIndicator(
      onRefresh: () async {
        await _loadGrades();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedGrades.length,
        itemBuilder: (context, index) {
          final grade = sortedGrades[index];
          return _buildGradeCard(context, grade, teacherId);
        },
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, String grade, String teacherId) {
    // If this is the special card, navigate to Grades1to5Page
    if (grade.toLowerCase().contains('1 to 5')) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Grades1to5Page()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/timetable.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View grades 1 to 5',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Format grade for API call (ensure it's in "Grade X" format)
          final formattedGrade = grade.contains('Grade') ? grade : 'Grade $grade';
          setState(() {
            _selectedGrade = formattedGrade;
            _showTimetable = true;
          });
          context.read<ScheduleBloc>().add(LoadTimetable(teacherId, formattedGrade));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/timetable.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.contains('Grade') ? grade : 'Grade $grade',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View timetable',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTimetableView(BuildContext context, List<Timetable> timetables, String selectedGrade, String teacherId, {VoidCallback? onBackToGrades}) {
    if (timetables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No timetable available for Grade $selectedGrade'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBackToGrades ?? () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to Grades'),
            ),
          ],
        ),
      );
    }

    // Sort timetables by index (guaranteed to be non-null)
    final sortedTimetables = List<Timetable>.from(timetables);
    sortedTimetables.sort((a, b) {
      if (a.displayId == null && b.displayId == null) return 0;
      if (a.displayId == null) return 1;
      if (b.displayId == null) return -1;
      return a.displayId!.compareTo(b.displayId!);
    });

    // Log sorted items for debugging
    for (final t in sortedTimetables) {
      // ignore: avoid_print
      print('[Timetable] index: ${t.index}, subject: ${t.subject}, day: ${t.day}, time: ${t.time}');
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
         
        ),
        // Timetable content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ScheduleBloc>().add(LoadTimetable(teacherId, selectedGrade));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedTimetables.length,
              itemBuilder: (context, index) {
                final timetable = sortedTimetables[index];
                return _buildTimetableItem(context, timetable);
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildTimetableItem(BuildContext context, Timetable timetable) {
    String? teacherImage;
    switch (timetable.teacherId) {
      case 1:
        teacherImage = 'assets/images/aruna2.jpeg';
        break;
      case 2:
        teacherImage = 'assets/images/sajith.jpeg';
        break;
      case 3:
        teacherImage = 'assets/images/mana.jpeg';
        break;
      case 4:
        teacherImage = 'assets/images/mahesh.jpeg';
        break;
      case 5:
        teacherImage = 'assets/images/indika.png';
        break;
      case 6:
        teacherImage = 'assets/images/samu2.jpeg';
        break;
      default:
        teacherImage = 'assets/images/timetable.jpg';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue top section with grade and subject
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${timetable.grade}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    timetable.subject,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      // fontFamily: 'IskoolaPota', // Uncomment if Sinhala font is available
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teacher image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    teacherImage ?? 'assets/images/timetable.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 18),
                // Teacher name and label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Ongoing lesson',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        timetable.topic ?? 'Introduction to the lesson',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Time values below the image, left-aligned
          Padding(
            padding: const EdgeInsets.only(left: 26, right: 10, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timetable.time.isNotEmpty)
                  Text(
                    timetable.time,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (timetable.time2 != null && timetable.time2!.isNotEmpty)
                  Text(
                    timetable.time2!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (timetable.time3 != null && timetable.time3!.isNotEmpty)
                  Text(
                    timetable.time3!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final gradeNum = int.tryParse(grade) ?? 0;
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[(gradeNum - 1) % colors.length];
  }

  Color _getDayColor(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return Colors.blue;
      case 'tuesday':
        return Colors.green;
      case 'wednesday':
        return Colors.orange;
      case 'thursday':
        return Colors.purple;
      case 'friday':
        return Colors.red;
      case 'saturday':
        return Colors.teal;
      case 'sunday':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  int _getDayOrder(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 999;
    }
  }
}

// New page for grades 1 to 5
class Grades1to5Page extends StatelessWidget {
  const Grades1to5Page({super.key});

  @override
  Widget build(BuildContext context) {
    final grades = ['1', '2', '3', '4', '5'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades 1 to 5'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grades.length,
        itemBuilder: (context, index) {
          final grade = grades[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to timetable for this grade
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeTimetablePage(grade: 'Grade $grade'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/timetable.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grade $grade',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View timetable',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// New page to show timetable for a specific grade (1-5)
class GradeTimetablePage extends StatefulWidget {
  final String grade;
  const GradeTimetablePage({super.key, required this.grade});

  @override
  State<GradeTimetablePage> createState() => _GradeTimetablePageState();
}

class _GradeTimetablePageState extends State<GradeTimetablePage> {
  String? teacherId;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      teacherId = user?.teacherId ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (teacherId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (context) => sl<ScheduleBloc>()..add(LoadTimetable(teacherId!, widget.grade)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.grade} Timetable'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            if (state is ScheduleInitial || state is ScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TimetableLoaded) {
              return _SchedulePageState._buildTimetableView(context, state.timetables, widget.grade, teacherId!);
            } else if (state is ScheduleError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No timetable available'));
          },
        ),
      ),
    );
  }
} 