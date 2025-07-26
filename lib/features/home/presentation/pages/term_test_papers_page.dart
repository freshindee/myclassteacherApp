import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/entities/term_test_paper.dart';
import '../bloc/term_test_paper_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_term_test_papers.dart';

class TermTestPapersPage extends StatefulWidget {
  const TermTestPapersPage({Key? key}) : super(key: key);

  @override
  State<TermTestPapersPage> createState() => _TermTestPapersPageState();
}

class _TermTestPapersPageState extends State<TermTestPapersPage> {
  String? selectedGrade;
  String? selectedSubject;
  int? selectedTerm;

  final List<String> grades = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'
  ];
  final List<String> subjects = [
    'සියලුම විෂයන්(1-5 වසර)', 'Mathematics', 'English', 'Science', 'ICT', 'Tamil', 'Sinhala', 'History', 'Geography',
     'Business studies', 'Civic'  
  ];
  final List<int> terms = [1, 2, 3];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Term Test Papers'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Grade:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedGrade,
                      hint: const Text('All'),
                      items: grades.map((grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text('Grade $grade'),
                        );
                      }).toList(),
                      onChanged: (grade) {
                        setState(() {
                          selectedGrade = grade;
                        });
                        _fetchFiltered(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Subject:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedSubject,
                      hint: const Text('All'),
                      items: subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (subject) {
                        setState(() {
                          selectedSubject = subject;
                        });
                        _fetchFiltered(context);
                      },
                    ),
                  ],
                ),
                 const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Term:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: selectedTerm,
                      hint: const Text('All'),
                      items: terms.map((term) {
                        return DropdownMenuItem<int>(
                          value: term,
                          child: Text('Term $term'),
                        );
                      }).toList(),
                      onChanged: (term) {
                        setState(() {
                          selectedTerm = term;
                        });
                        _fetchFiltered(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TermTestPaperBloc, TermTestPaperState>(
              builder: (context, state) {
                if (state is TermTestPaperLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TermTestPaperLoaded) {
                  if (state.papers.isEmpty) {
                    return const Center(
                      child: Text('No term test papers found.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.papers.length,
                    itemBuilder: (context, index) {
                      final paper = state.papers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _openPdf(context, paper.pdfUrl),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                   "Grade: ${paper.grade} | Subject: ${paper.subject} | Term: ${paper.term.toString()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  paper.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  paper.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is TermTestPaperError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: Text('No data.'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _fetchFiltered(BuildContext context) {
    if (selectedGrade != null && selectedSubject != null && selectedTerm != null) {
      context.read<TermTestPaperBloc>().add(FetchTermTestPapers(
        grade: selectedGrade,
        subject: selectedSubject,
        term: selectedTerm,
      ));
    }
  }

  void _openPdf(BuildContext context, String pdfUrl) {
    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF URL available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('PDF Viewer'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.network(pdfUrl),
        ),
      ),
    );
  }
} 