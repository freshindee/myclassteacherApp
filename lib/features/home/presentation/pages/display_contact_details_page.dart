import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/api_endpoints.dart';

/// Learning Journey Page - Shows exam progress and history
class DisplayContactDetailsPage extends StatefulWidget {
  const DisplayContactDetailsPage({super.key});

  @override
  State<DisplayContactDetailsPage> createState() => _DisplayContactDetailsPageState();
}

class _DisplayContactDetailsPageState extends State<DisplayContactDetailsPage> {
  bool _isLoading = true;
  List<ExamAttempt> _attempts = [];
  double _avgScore = 0.0;
  int _totalExams = 0;
  int _studyHours = 0;

  final ApiClient _apiClient = sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    _loadLearningJourney();
  }

  Future<void> _loadLearningJourney() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID
      final userId = await UserSessionService.getUserId();
      if (userId == null || userId.isEmpty) {
        print('❌ [LEARNING JOURNEY] User ID is null or empty');
        setState(() {
          _attempts = [];
          _isLoading = false;
        });
        return;
      }

      print('📊 [LEARNING JOURNEY] Fetching exam history for user: $userId');

      // Remove leading slash if present
      final endpoint = ApiEndpoints.examHistory.startsWith('/')
          ? ApiEndpoints.examHistory.substring(1)
          : ApiEndpoints.examHistory;

      // Call API to fetch exam history
      final response = await _apiClient.get(
        endpoint,
        queryParameters: {'user_id': userId},
      );

      if (!response.isSuccess) {
        print('❌ [LEARNING JOURNEY] API Error: ${response.error}');
        setState(() {
          _attempts = [];
        });
        return;
      }

      final data = response.data;
      if (data == null) {
        print('❌ [LEARNING JOURNEY] Response data is null');
        setState(() {
          _attempts = [];
        });
        return;
      }

      // Parse the response - could be {"records": [...]} or direct array
      List<dynamic> records;
      if (data is Map<String, dynamic>) {
        records = data['records'] as List<dynamic>? ?? [];
      } else if (data is List) {
        records = data;
      } else {
        print('❌ [LEARNING JOURNEY] Unexpected response format: ${data.runtimeType}');
        setState(() {
          _attempts = [];
        });
        return;
      }

      print('📊 [LEARNING JOURNEY] Received ${records.length} exam history records');

      // Convert to ExamAttempt objects
      _attempts = records.map((record) {
        return _parseExamAttempt(record as Map<String, dynamic>);
      }).toList();

      // Sort by completed_at (most recent first)
      _attempts.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      // Calculate stats from attempts
      _calculateStats();

      print('📊 [LEARNING JOURNEY] Successfully loaded ${_attempts.length} attempts');
    } catch (e) {
      print('❌ [LEARNING JOURNEY] Error loading data: $e');
      setState(() {
        _attempts = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ExamAttempt _parseExamAttempt(Map<String, dynamic> json) {
    // Parse id
    int id = json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    
    // Parse paper_id
    int paperId = json['paper_id'] is int 
        ? json['paper_id'] as int 
        : int.tryParse(json['paper_id'].toString()) ?? 0;
    
    // Parse score - could be string or double
    double score = 0.0;
    if (json['score'] != null) {
      if (json['score'] is num) {
        score = (json['score'] as num).toDouble();
      } else if (json['score'] is String) {
        score = double.tryParse(json['score']) ?? 0.0;
      }
    }
    
    // Parse completed_at timestamp
    DateTime completedAt = DateTime.now();
    if (json['completed_at'] != null) {
      try {
        final dateStr = json['completed_at'].toString();
        // Try parsing MySQL datetime format: "2026-01-16 21:09:46"
        completedAt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
      } catch (e) {
        print('⚠️ [LEARNING JOURNEY] Error parsing date: ${json['completed_at']}, error: $e');
        completedAt = DateTime.now();
      }
    }
    
    // Parse duration (in seconds, convert to minutes)
    int durationMinutes = 0;
    if (json['duration'] != null) {
      int durationSeconds = 0;
      if (json['duration'] is int) {
        durationSeconds = json['duration'] as int;
      } else if (json['duration'] is String) {
        durationSeconds = int.tryParse(json['duration']) ?? 0;
      }
      durationMinutes = durationSeconds ~/ 60; // Convert to minutes
    }
    
    // Parse attempt_id
    int attemptId = json['attempt_id'] is int 
        ? json['attempt_id'] as int 
        : int.tryParse(json['attempt_id'].toString()) ?? 0;

    // Format date/time for display
    final now = DateTime.now();
    final difference = now.difference(completedAt);
    String dateTimeStr;
    if (difference.inDays == 0) {
      // Today
      dateTimeStr = 'Today • ${DateFormat('HH:mm').format(completedAt)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      dateTimeStr = 'Yesterday • ${DateFormat('HH:mm').format(completedAt)}';
    } else if (difference.inDays < 7) {
      // This week
      dateTimeStr = '${difference.inDays} days ago • ${DateFormat('HH:mm').format(completedAt)}';
    } else {
      // Older
      dateTimeStr = DateFormat('MMM dd • HH:mm').format(completedAt);
    }

    // Get paper name from API response
    String subjectTopic = 'Paper #$paperId'; // Fallback
    if (json['paper_name'] != null && json['paper_name'].toString().isNotEmpty) {
      subjectTopic = json['paper_name'].toString();
    } else if (json['paper_title'] != null && json['paper_title'].toString().isNotEmpty) {
      subjectTopic = json['paper_title'].toString();
    } else if (json['subject_name'] != null && json['chapter_name'] != null) {
      subjectTopic = '${json['subject_name']}: ${json['chapter_name']}';
    } else if (json['subject_name'] != null) {
      subjectTopic = json['subject_name'].toString();
    }

    // Get image URL if available
    String? imageUrl;
    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      imageUrl = json['image_url'].toString();
    }

    return ExamAttempt(
      id: id,
      paperId: paperId,
      scorePercentage: score, // API returns score as percentage or marks, adjust if needed
      attemptNumber: attemptId + 1, // attempt_id is 0-indexed, display as 1-indexed
      subjectTopic: subjectTopic,
      dateTime: dateTimeStr,
      completedAt: completedAt,
      durationMinutes: durationMinutes,
      imageUrl: imageUrl,
      hasProgressBar: false,
    );
  }

  void _calculateStats() {
    if (_attempts.isEmpty) {
      _avgScore = 0.0;
      _totalExams = 0;
      _studyHours = 0;
      return;
    }

    // Calculate average score
    double totalScore = 0.0;
    int totalDuration = 0;
    for (var attempt in _attempts) {
      totalScore += attempt.scorePercentage;
      totalDuration += attempt.durationMinutes;
    }
    _avgScore = totalScore / _attempts.length;
    _totalExams = _attempts.length;
    _studyHours = totalDuration ~/ 60; // Convert minutes to hours
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8), // background-light
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top App Bar (Fixed)
                _buildTopAppBar(),
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Summary Section
                        _buildSummarySection(),
                        // History Section Header
                        _buildHistoryHeader(),
                        // History List
                        _buildHistoryList(),
                        // Bottom padding for last item
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.blue,
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              'Learning Journey',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
                color: Colors.white,
              ),
            ),
          ),
          // Spacer
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Circular Progress Indicator
          _buildCircularProgress(),
          const SizedBox(height: 24),
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Exams',
                  '$_totalExams',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Study Hours',
                  '${_studyHours}h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress() {
    return Container(
      width: 192,
      height: 192,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Radial gradient for progress circle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CircularProgressPainter(
          progress: _avgScore / 100,
          backgroundColor: const Color(0xFFE2E8F0),
          progressColor: const Color(0xFF137FEC),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_avgScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Avg. Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Color(0xFF111418),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
              color: Color(0xFF111418),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement filter functionality
            },
            child: const Text(
              'Filter',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF137FEC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_attempts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.query_stats,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No exam attempts yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _attempts.length,
      itemBuilder: (context, index) {
        return _buildAttemptCard(_attempts[index]);
      },
    );
  }

  Widget _buildAttemptCard(ExamAttempt attempt) {
    // Determine score color - green for high scores
    Color scoreColor;
    if (attempt.scorePercentage >= 80) {
      scoreColor = Colors.green;
    } else if (attempt.scorePercentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade50,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content - Text information
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score and Attempt badge in one row
                  Row(
                    children: [
                      // Large score percentage
                      Text(
                        '${attempt.scorePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Attempt badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ATTEMPT #${attempt.attemptNumber}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF137FEC),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Subject and topic - can wrap to two lines
                  Text(
                    attempt.subjectTopic,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Color(0xFF111418),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Date and time
                  Text(
                    attempt.dateTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // View Details button
                  _buildViewDetailsButton(),
                ],
              ),
            ),
            // Right side - Image thumbnail
            if (attempt.imageUrl != null) ...[
              const SizedBox(width: 16),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(attempt.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewDetailsButton() {
    return InkWell(
      onTap: () {
        // TODO: Navigate to exam details page
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'View Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111418),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomNavItem(Icons.home, 'Home', false),
          _buildBottomNavItem(Icons.menu_book, 'Exams', false),
          _buildBottomNavItem(Icons.query_stats, 'Progress', true),
          _buildBottomNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 26,
          color: isSelected ? const Color(0xFF137FEC) : Colors.grey.shade400,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF137FEC) : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final startAngle = -90 * (3.14159 / 180); // Start from top
    final sweepAngle = 360 * progress * (3.14159 / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Exam Attempt model
class ExamAttempt {
  final int id;
  final int paperId;
  final double scorePercentage;
  final int attemptNumber;
  final String subjectTopic;
  final String dateTime;
  final DateTime completedAt;
  final int durationMinutes;
  final String? imageUrl;
  final bool hasProgressBar;

  ExamAttempt({
    required this.id,
    required this.paperId,
    required this.scorePercentage,
    required this.attemptNumber,
    required this.subjectTopic,
    required this.dateTime,
    required this.completedAt,
    required this.durationMinutes,
    this.imageUrl,
    this.hasProgressBar = false,
  });
}
