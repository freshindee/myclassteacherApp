import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_page.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/master_data_service.dart';

class Grade {
  final String id;
  final String name;

  Grade({required this.id, required this.name});

  factory Grade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grade(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
    );
  }
}

class GradesListPage extends StatefulWidget {
  const GradesListPage({Key? key}) : super(key: key);

  @override
  State<GradesListPage> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  String? teacherId;
  List<Grade> _grades = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _loadGrades();
  }

  Future<void> _loadTeacherId() async {
    final user = await UserSessionService.getCurrentUser();
    setState(() {
      teacherId = user?.teacherId ?? '';
    });
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('📋 [DEBUG] GradesListPage - Starting to load grades from master data');
      
      // First try to get from teacher master data (master_teacher collection)
      final masterData = await MasterDataService.getTeacherMasterData();
      print('📋 [DEBUG] GradesListPage - Master data result: ${masterData != null ? "Found" : "Not found"}');
      
      if (masterData != null && masterData.grades.isNotEmpty) {
        print('📋 [DEBUG] GradesListPage - Master data grades: ${masterData.grades}');
        
        // Convert grade strings to Grade objects
        final grades = masterData.grades.map((gradeName) {
          return Grade(
            id: gradeName,
            name: gradeName,
          );
        }).toList();
        
        setState(() {
          _grades = grades;
          _isLoading = false;
        });
        print('✅ [DEBUG] GradesListPage - Successfully loaded ${_grades.length} grades from master_teacher collection');
        print('✅ [DEBUG] GradesListPage - Grades: ${_grades.map((g) => g.name).toList()}');
        return;
      }
      
      // Fallback to Grade entities from master data
      print('📋 [DEBUG] GradesListPage - Trying fallback: loading from Grade entities');
      final gradeEntities = await MasterDataService.getGrades();
      print('📋 [DEBUG] GradesListPage - Grade entities count: ${gradeEntities.length}');
      
      if (gradeEntities.isNotEmpty) {
        final grades = gradeEntities.map((g) {
          return Grade(
            id: g.id,
            name: g.name,
          );
        }).toList();
        
        setState(() {
          _grades = grades;
          _isLoading = false;
        });
        print('⚠️ [DEBUG] GradesListPage - Loaded ${_grades.length} grades from Grade entities (fallback)');
        print('⚠️ [DEBUG] GradesListPage - Grades: ${_grades.map((g) => g.name).toList()}');
        print('⚠️ [WARNING] GradesListPage - Using fallback grades collection instead of master_teacher!');
        return;
      }
      
      // If no grades found, set empty list
      setState(() {
        _grades = [];
        _isLoading = false;
      });
      print('❌ [DEBUG] GradesListPage - No grades found in master data');
    } catch (e) {
      print('❌ [DEBUG] GradesListPage - Error loading grades: $e');
      setState(() {
        _error = e.toString();
        _grades = [];
        _isLoading = false;
      });
    }
  }

  /// Extracts numeric grade value from grade name for sorting
  /// Handles formats like "Grade 1", "Grade 1 to 5", "1", etc.
  int _extractGradeValue(String gradeName) {
    // Remove common prefixes and convert to lowercase
    final cleaned = gradeName.toLowerCase().replaceAll('grade', '').trim();
    
    // Handle ranges like "1 to 5" or "1-5"
    if (cleaned.contains('to') || cleaned.contains('-')) {
      final parts = cleaned.split(RegExp(r'\s*(to|-)\s*'));
      if (parts.isNotEmpty) {
        final firstNum = int.tryParse(parts[0].trim());
        if (firstNum != null) {
          // Return a value that puts ranges first (negative) or use first number
          return firstNum;
        }
      }
    }
    
    // Extract first number from the string
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 999;
    }
    
    // If no number found, return a high value to put at end
    return 999;
  }

  @override
  Widget build(BuildContext context) {
    if (teacherId == null || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadGrades();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_grades.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('පන්ති කාල සටහන'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No grades available'),
            ],
          ),
        ),
      );
    }

    // Sort grades by their numeric values extracted from grade names
    final sortedGrades = List<Grade>.from(_grades);
    sortedGrades.sort((a, b) {
      final aValue = _extractGradeValue(a.name);
      final bValue = _extractGradeValue(b.name);
      
      // If values are equal, sort alphabetically by name
      if (aValue == bValue) {
        return a.name.compareTo(b.name);
      }
      
      return aValue.compareTo(bValue);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('පන්ති කාල සටහන'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadGrades();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedGrades.length,
          itemBuilder: (context, index) {
            final grade = sortedGrades[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.calendar_month, size: 48, color: Colors.blue),
                ),
                title: Text(
                  grade.name.contains('Grade') ? grade.name : 'Grade ${grade.name}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              //  subtitle: const Text('View timetable', style: TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, size: 32, color: Colors.grey),
                onTap: () {
                  final gradeName = grade.name.contains('Grade') ? grade.name : 'Grade ${grade.name}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GradeTimetablePage(grade: gradeName),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
} 