import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_page.dart';

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

class GradesListPage extends StatelessWidget {
  const GradesListPage({Key? key}) : super(key: key);

  Future<List<Grade>> fetchGrades() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('grades').get();
    return querySnapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පන්ති කාල සටහන'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Grade>>(
        future: fetchGrades(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error:  [${snapshot.error}]'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No grades available'));
          }
          final grades = snapshot.data!;
          grades.sort((a, b) {
            final aId = int.tryParse(a.id) ?? a.id.hashCode;
            final bId = int.tryParse(b.id) ?? b.id.hashCode;
            return aId.compareTo(bId);
          });
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
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
                    grade.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                //  subtitle: const Text('View timetable', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, size: 32, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GradeTimetablePage(grade: grade.name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 