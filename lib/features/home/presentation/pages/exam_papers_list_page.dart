import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_exam_papers.dart';
import '../../domain/entities/exam_paper.dart';
import 'exam_questions_page.dart';

class ExamPapersListPage extends StatefulWidget {
  final String grade;
  final int subjectId;
  final int? chapterId;
  final String subjectName;
  final String? chapterName;

  const ExamPapersListPage({
    super.key,
    required this.grade,
    required this.subjectId,
    this.chapterId,
    required this.subjectName,
    this.chapterName,
  });

  @override
  State<ExamPapersListPage> createState() => _ExamPapersListPageState();
}

class _ExamPapersListPageState extends State<ExamPapersListPage> {
  List<ExamPaper> _papers = [];
  bool _isLoading = true;
  String? _error;

  final GetExamPapers _getExamPapers = sl<GetExamPapers>();

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📝 [DEBUG] ExamPapersListPage - Loading papers');
      print('📝 [DEBUG] - grade: ${widget.grade}, subjectId: ${widget.subjectId}, chapterId: ${widget.chapterId}');

      final result = await _getExamPapers(GetExamPapersParams(
        grade: widget.grade,
        subjectId: widget.subjectId,
        chapterId: widget.chapterId,
      ));

      result.fold(
        (failure) {
          print('❌ [DEBUG] ExamPapersListPage - Failed to load papers: ${failure.message}');
          setState(() {
            _error = failure.message;
            _papers = [];
            _isLoading = false;
          });
        },
        (papers) {
          print('✅ [DEBUG] ExamPapersListPage - Successfully loaded ${papers.length} papers');
          setState(() {
            _papers = papers;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('❌ [DEBUG] ExamPapersListPage - Error loading papers: $e');
      setState(() {
        _error = e.toString();
        _papers = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _papers.isEmpty
                  ? _buildEmptyView()
                  : _buildPapersList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'දෝෂයක් ඇති විය',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPapers,
              icon: const Icon(Icons.refresh),
              label: const Text('නැවත උත්සාහ කරන්න'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'විභාග නොමැත',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'මෙම ශ්‍රේණිය, විෂය සහ පාඩම සඳහා විභාග නොමැත',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPapersList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade600,
          ],
        ),
      ),
      child: Column(
        children: [
          // Fixed App Bar (Not scrollable)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  const Expanded(
                    child: Text(
                      'විභාග ලැයිස්තුව',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Scrollable Content (Header Card + Papers List)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card (Light Blue Semi-transparent)
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grade
                        Row(
                          children: [
                            const Icon(
                              Icons.school,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ශ්‍රේණිය: Grade ${widget.grade}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Subject
                        Row(
                          children: [
                            const Icon(
                              Icons.science,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'විෂය: ${widget.subjectName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (widget.chapterName != null) ...[
                          const SizedBox(height: 12),
                          // Chapter
                          Row(
                            children: [
                              const Icon(
                                Icons.book,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'පාඩම: ${widget.chapterName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Exams found button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade300.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'සොයාගත් විභාග : ${_papers.length.toString().padLeft(2, '0')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Papers List (Light grey background section)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _papers.length,
                      itemBuilder: (context, index) {
                        final paper = _papers[index];
                        return _buildPaperCard(paper);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperCard(ExamPaper paper) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Options Menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    paper.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade600,
                  ),
                  onSelected: (value) {
                    // Handle menu selection (can be implemented later)
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info Chips
            Row(
              children: [
                _buildInfoChip(
                  Icons.access_time,
                  '${paper.timeLimit} min',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.star,
                  '${paper.totalMarks} marks',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.school,
                  'Term ${paper.term}',
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Curriculum
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  paper.stream.isNotEmpty ? paper.stream : 'Local Curriculum',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Start Exam Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to exam questions page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamQuestionsPage(
                        paperId: paper.paperId,
                        paperTitle: paper.title,
                        subjectName: widget.subjectName,
                        grade: widget.grade,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade300, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
