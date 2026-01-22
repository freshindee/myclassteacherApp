import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_exam_questions.dart';
import '../../domain/entities/exam_question.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class ExamQuestionsPage extends StatefulWidget {
  final int paperId;
  final String paperTitle;
  final String? subjectName;
  final String? grade;

  const ExamQuestionsPage({
    super.key,
    required this.paperId,
    required this.paperTitle,
    this.subjectName,
    this.grade,
  });

  @override
  State<ExamQuestionsPage> createState() => _ExamQuestionsPageState();
}

class _ExamQuestionsPageState extends State<ExamQuestionsPage> {
  List<ExamQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;
  int _currentQuestionIndex = 0;
  Map<int, String?> _selectedAnswers = {}; // questionId -> selected option
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalTimeSeconds = 0;
  bool _isPaused = false;
  bool _showSummary = false;
  bool _showReportDialog = false;
  String _selectedIssueType = 'Incorrect Question'; // Default selection
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmittingReport = false;
  int _descriptionLength = 0;
  bool _isSavingMarks = false; // Track if marks are currently being saved (prevent concurrent saves)

  final GetExamQuestions _getExamQuestions = sl<GetExamQuestions>();
  final ApiClient _apiClient = sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📝 [DEBUG] ExamQuestionsPage - Loading questions for paperId: ${widget.paperId}');

      final result = await _getExamQuestions(widget.paperId);

      result.fold(
        (failure) {
          print('❌ [DEBUG] ExamQuestionsPage - Failed to load questions: ${failure.message}');
          setState(() {
            _error = failure.message;
            _questions = [];
            _isLoading = false;
          });
        },
        (questions) {
          print('✅ [DEBUG] ExamQuestionsPage - Successfully loaded ${questions.length} questions');
          
          // Log all questions data to console
          print('📋 [QUESTIONS DATA] Total questions: ${questions.length}');
          for (var i = 0; i < questions.length; i++) {
            final q = questions[i];
            print('📋 [QUESTION ${i + 1}]');
            print('   - id: ${q.id}');
            print('   - paper_id: ${q.paperId}');
            print('   - subject_id: ${q.subjectId}');
            print('   - chapter_id: ${q.chapterId}');
            print('   - question_text: ${q.questionText}');
            print('   - image_url: ${q.imageUrl ?? "null"}');
            print('   - option_a_text: ${q.optionAText ?? "null"}');
            print('   - option_b_text: ${q.optionBText ?? "null"}');
            print('   - option_c_text: ${q.optionCText ?? "null"}');
            print('   - option_d_text: ${q.optionDText ?? "null"}');
            print('   - option_a_image: ${q.optionAImage ?? "null"}');
            print('   - option_b_image: ${q.optionBImage ?? "null"}');
            print('   - option_c_image: ${q.optionCImage ?? "null"}');
            print('   - option_d_image: ${q.optionDImage ?? "null"}');
            print('   - hasTextOptions: ${q.hasTextOptions}');
            print('   - hasImageOptions: ${q.hasImageOptions}');
            print('   - correct_option: ${q.correctOption}');
            print('   - explanation: ${q.explanation ?? "null"}');
            print('   - type: ${q.type}');
            print('   - marks: ${q.marks}');
            print('');
          }
          
          // Initialize timer (default 60 minutes = 3600 seconds)
          // You can get time_limit from paper if available
          _totalTimeSeconds = 60 * 60; // Default 60 minutes
          _remainingSeconds = _totalTimeSeconds;
          _startTimer();
          
          setState(() {
            _questions = questions;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('❌ [DEBUG] ExamQuestionsPage - Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _questions = [];
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('කාලය අවසන්'),
        content: const Text('විභාග කාලය අවසන් විය.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Helper method to convert option letter to position (A=1, B=2, C=3, D=4)
  int _optionLetterToPosition(String letter) {
    switch (letter.toUpperCase()) {
      case 'A': return 1;
      case 'B': return 2;
      case 'C': return 3;
      case 'D': return 4;
      default: return 0;
    }
  }

  // Helper method to convert position to option letter (1=A, 2=B, 3=C, 4=D)
  String _positionToOptionLetter(int position) {
    switch (position) {
      case 1: return 'A';
      case 2: return 'B';
      case 3: return 'C';
      case 4: return 'D';
      default: return '';
    }
  }

  // Helper method to get correct option position from database
  // Handles both numeric (1,2,3,4) and letter (A,B,C,D) formats
  int _getCorrectOptionPosition(ExamQuestion question) {
    final correctOption = question.correctOption.trim();
    
    // Try to parse as integer (1, 2, 3, 4)
    final intValue = int.tryParse(correctOption);
    if (intValue != null && intValue >= 1 && intValue <= 4) {
      return intValue;
    }
    
    // Try to parse as letter (A, B, C, D)
    return _optionLetterToPosition(correctOption);
  }

  void _onAnswerSelected(String option) {
    // Convert option letter (A, B, C, D) to position (1, 2, 3, 4) and store
    final position = _optionLetterToPosition(option);
    final questionId = _questions[_currentQuestionIndex].id;
    final correctPosition = _getCorrectOptionPosition(_questions[_currentQuestionIndex]);
    
    print('📝 [ANSWER SELECTED] Option: $option, Position: $position, Question ID: $questionId');
    print('📝 [ANSWER SELECTED] Correct position from DB: $correctPosition');
    
    setState(() {
      _selectedAnswers[questionId] = position.toString();
    });
  }

  void _onPrevious() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _onNext() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _onPause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (!_isPaused) {
      _startTimer();
    }
  }

  void _onFinishEarly() {
    setState(() {
      _showSummary = true;
      _isPaused = true;
    });
    // Save marks when exam is finished
    _savePaperMarks();
  }

  void _closeSummary() {
    setState(() {
      _showSummary = false;
      _isPaused = false;
    });
  }

  void _backToPapers() {
    Navigator.of(context).pop();
  }

  int _getAnsweredCount() {
    return _selectedAnswers.values.where((answer) => answer != null).length;
  }

  int _getCorrectCount() {
    int correct = 0;
    for (var question in _questions) {
      final selectedPositionStr = _selectedAnswers[question.id];
      if (selectedPositionStr != null) {
        final selectedPosition = int.tryParse(selectedPositionStr) ?? 0;
        final correctPosition = _getCorrectOptionPosition(question);
        
        if (selectedPosition == correctPosition && selectedPosition >= 1 && selectedPosition <= 4) {
          correct++;
        }
      }
    }
    return correct;
  }

  int _getWrongCount() {
    int wrong = 0;
    for (var question in _questions) {
      final selectedPositionStr = _selectedAnswers[question.id];
      if (selectedPositionStr != null) {
        final selectedPosition = int.tryParse(selectedPositionStr) ?? 0;
        final correctPosition = _getCorrectOptionPosition(question);
        
        if (selectedPosition != correctPosition && selectedPosition >= 1 && selectedPosition <= 4) {
          wrong++;
        }
      }
    }
    return wrong;
  }

  double _getScorePercentage() {
    if (_questions.isEmpty) return 0.0;
    final totalMarks = _getTotalMarks();
    if (totalMarks == 0) return 0.0;
    final earnedMarks = _getEarnedMarks();
    return (earnedMarks / totalMarks) * 100;
  }

  // Calculate total marks for all questions
  double _getTotalMarks() {
    double total = 0.0;
    for (var question in _questions) {
      total += question.marks;
    }
    return total;
  }

  // Calculate earned marks based on correct answers
  double _getEarnedMarks() {
    double earned = 0.0;
    for (var question in _questions) {
      final selectedPositionStr = _selectedAnswers[question.id];
      if (selectedPositionStr != null) {
        final selectedPosition = int.tryParse(selectedPositionStr) ?? 0;
        final correctPosition = _getCorrectOptionPosition(question);
        
        if (selectedPosition == correctPosition && selectedPosition >= 1 && selectedPosition <= 4) {
          earned += question.marks;
        }
      }
    }
    return earned;
  }

  double _getAnsweredProgress() {
    if (_questions.isEmpty) return 0.0;
    return _getAnsweredCount() / _questions.length;
  }

  double _getTimeProgress() {
    if (_totalTimeSeconds == 0) return 0.0;
    return (_totalTimeSeconds - _remainingSeconds) / _totalTimeSeconds;
  }

  String _getQuestionStatus(int questionIndex) {
    if (questionIndex >= _questions.length) return 'unanswered';
    final question = _questions[questionIndex];
    final selectedPositionStr = _selectedAnswers[question.id];
    if (selectedPositionStr == null) return 'unanswered';
    
    final selectedPosition = int.tryParse(selectedPositionStr) ?? 0;
    final correctPosition = _getCorrectOptionPosition(question);
    
    if (selectedPosition == correctPosition && selectedPosition >= 1 && selectedPosition <= 4) {
      return 'correct';
    }
    return 'wrong';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _questions.isEmpty
                  ? _buildEmptyView()
                  : Stack(
                      children: [
                        _buildExamView(),
                        if (_showSummary) _buildSummaryModal(),
                        if (_showReportDialog) _buildReportDialog(),
                      ],
                    ),
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
              onPressed: _loadQuestions,
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
            Icon(Icons.help_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'ප්‍රශ්න නොමැත',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamView() {
    final currentQuestion = _questions[_currentQuestionIndex];
    // Convert stored position (1,2,3,4) back to letter (A,B,C,D) for UI display
    final selectedPositionStr = _selectedAnswers[currentQuestion.id];
    final selectedAnswer = selectedPositionStr != null 
        ? _positionToOptionLetter(int.tryParse(selectedPositionStr) ?? 0)
        : null;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        // Header
        Container(
          color: Colors.green.shade600,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectName != null && widget.grade != null
                              ? '${widget.subjectName} - ${widget.grade} ශ්‍රේණිය'
                              : widget.paperTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.paperTitle.isNotEmpty)
                          Text(
                            widget.paperTitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSummary = true;
                        _isPaused = true;
                      });
                    },
                    icon: const Icon(Icons.summarize, color: Colors.white, size: 18),
                    label: const Text(
                      'View Summary',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Pause Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onPause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Finish Early Button (only show if not on last question)
              if (_currentQuestionIndex < _questions.length - 1)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onFinishEarly,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Finish Early'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Progress Bar
        Container(
          height: 4,
          color: Colors.grey.shade200,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              color: Colors.green.shade600,
            ),
          ),
        ),

        // Question Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Text
                    Text(
                      currentQuestion.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question Image (if available)
                    if (currentQuestion.imageUrl != null &&
                        currentQuestion.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Image.network(
                          currentQuestion.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),

                    // Options - Check if question has text or image options
                    if (currentQuestion.hasTextOptions)
                      ...[
                        // Text Options
                        _buildTextOption(
                          'A',
                          currentQuestion.optionAText ?? '',
                          selectedAnswer == 'A',
                          () => _onAnswerSelected('A'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'B',
                          currentQuestion.optionBText ?? '',
                          selectedAnswer == 'B',
                          () => _onAnswerSelected('B'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'C',
                          currentQuestion.optionCText ?? '',
                          selectedAnswer == 'C',
                          () => _onAnswerSelected('C'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'D',
                          currentQuestion.optionDText ?? '',
                          selectedAnswer == 'D',
                          () => _onAnswerSelected('D'),
                        ),
                      ]
                    else if (currentQuestion.hasImageOptions)
                      ...[
                        // Image Options
                        _buildImageOption(
                          'A',
                          currentQuestion.optionAImage ?? '',
                          selectedAnswer == 'A',
                          () => _onAnswerSelected('A'),
                        ),
                        const SizedBox(height: 12),
                        _buildImageOption(
                          'B',
                          currentQuestion.optionBImage ?? '',
                          selectedAnswer == 'B',
                          () => _onAnswerSelected('B'),
                        ),
                        const SizedBox(height: 12),
                        _buildImageOption(
                          'C',
                          currentQuestion.optionCImage ?? '',
                          selectedAnswer == 'C',
                          () => _onAnswerSelected('C'),
                        ),
                        const SizedBox(height: 12),
                        _buildImageOption(
                          'D',
                          currentQuestion.optionDImage ?? '',
                          selectedAnswer == 'D',
                          () => _onAnswerSelected('D'),
                        ),
                      ]
                    else
                      ...[
                        // Fallback to legacy format (backward compatibility)
                        _buildTextOption(
                          'A',
                          currentQuestion.optionA,
                          selectedAnswer == 'A',
                          () => _onAnswerSelected('A'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'B',
                          currentQuestion.optionB,
                          selectedAnswer == 'B',
                          () => _onAnswerSelected('B'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'C',
                          currentQuestion.optionC,
                          selectedAnswer == 'C',
                          () => _onAnswerSelected('C'),
                        ),
                        const SizedBox(height: 12),
                        _buildTextOption(
                          'D',
                          currentQuestion.optionD,
                          selectedAnswer == 'D',
                          () => _onAnswerSelected('D'),
                        ),
                      ],

                    const SizedBox(height: 24),

                    // Report Issue
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showReportDialog = true;
                            _selectedIssueType = 'Incorrect Question';
                            _descriptionController.clear();
                            _descriptionLength = 0;
                          });
                        },
                        icon: const Icon(Icons.flag, size: 16),
                        label: const Text('Report an issue'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom Navigation
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Previous Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentQuestionIndex > 0 ? _onPrevious : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Question Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next/Finish Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentQuestionIndex < _questions.length - 1
                      ? _onNext
                      : _onFinishEarly,
                  icon: Icon(
                    _currentQuestionIndex < _questions.length - 1
                        ? Icons.arrow_forward
                        : Icons.check,
                    size: 18,
                  ),
                  label: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next'
                        : 'Finish',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentQuestionIndex < _questions.length - 1
                        ? Colors.green.shade600
                        : Colors.teal.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextOption(String label, String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.green.shade600 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label. $text',
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.green.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(String label, String imageUrl, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.green.shade600 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                        );
                      },
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

  Widget _buildSummaryModal() {
    final answeredCount = _getAnsweredCount();
    final correctCount = _getCorrectCount();
    final wrongCount = _getWrongCount();
    final totalCount = _questions.length;
    final score = _getScorePercentage();
    final earnedMarks = _getEarnedMarks();
    final totalMarks = _getTotalMarks();
    final answeredProgress = _getAnsweredProgress();
    final timeProgress = _getTimeProgress();

    // Debug logging for summary counts
    print('📊 [SUMMARY] Answered: $answeredCount, Correct: $correctCount, Wrong: $wrongCount, Total: $totalCount');
    print('📊 [SUMMARY] Selected answers: $_selectedAnswers');

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Modal content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.subjectName ?? 'විභාගය',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.grade ?? ""} ශ්‍රේණිය • 2023 • MCQ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Summary boxes
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryBox(
                              'Answered',
                              answeredCount.toString(),
                              Colors.cyan.shade50,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'Correct',
                              correctCount.toString(),
                              Colors.green.shade50,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'Wrong',
                              wrongCount.toString(),
                              Colors.red.shade50,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'Total',
                              totalCount.toString(),
                              Colors.blue.shade50,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress bars
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Answered',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(answeredProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: answeredProgress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.cyan.shade400,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(timeProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: timeProgress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.cyan.shade400,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Marks and Score
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Marks: ${earnedMarks.toStringAsFixed(1)}/${totalMarks.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Score: ${score.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Question grid
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          final status = _getQuestionStatus(index);
                          return _buildQuestionNumberButton(index + 1, status);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _backToPapers,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade700,
                          side: BorderSide(color: Colors.teal.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to Papers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _closeSummary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNumberButton(int number, String status) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (status) {
      case 'correct':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        break;
      case 'wrong':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _currentQuestionIndex = number - 1;
          _showSummary = false;
          _isPaused = false;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportDialog() {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.flag,
                        color: Colors.teal.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Report Question',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Issue Type Selection
                      const Text(
                        'What seems to be the issue?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIssueTypeChip(
                              'Incorrect Question',
                              _selectedIssueType == 'Incorrect Question',
                              () {
                                setState(() {
                                  _selectedIssueType = 'Incorrect Question';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildIssueTypeChip(
                              'Incorrect Answer',
                              _selectedIssueType == 'Incorrect Answer',
                              () {
                                setState(() {
                                  _selectedIssueType = 'Incorrect Answer';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildIssueTypeChip(
                              'Other',
                              _selectedIssueType == 'Other',
                              () {
                                setState(() {
                                  _selectedIssueType = 'Other';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description Input
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLength: 400,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Add any helpful details (links, expected answer, etc.)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          counterText: 'Optional – but details help us act $_descriptionLength/400 faster',
                          counterStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _descriptionLength = value.length;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isSubmittingReport
                            ? null
                            : () {
                                setState(() {
                                  _showReportDialog = false;
                                  _descriptionController.clear();
                                  _selectedIssueType = 'Incorrect Question';
                                });
                              },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmittingReport ? null : _submitReport,
                        icon: _isSubmittingReport
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _isSubmittingReport ? 'Submitting...' : 'Submit',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypeChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade700 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            if (isSelected) const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_isSubmittingReport) return;

    setState(() {
      _isSubmittingReport = true;
    });

    try {
      final userId = await UserSessionService.getUserId();
      final currentQuestion = _questions[_currentQuestionIndex];
      final description = _descriptionController.text.trim();

      print('📝 [REPORT] Submitting report:');
      print('   - Question ID: ${currentQuestion.id}');
      print('   - Issue Type: $_selectedIssueType');
      print('   - Description: $description');
      print('   - User ID: $userId');

      // Remove leading slash if present to avoid double slash in URL
      final endpoint = ApiEndpoints.reportQuestion.startsWith('/')
          ? ApiEndpoints.reportQuestion.substring(1)
          : ApiEndpoints.reportQuestion;
      
      final response = await _apiClient.post(
        endpoint,
        body: {
          'question_id': currentQuestion.id,
          'paper_id': widget.paperId,
          'issue': _selectedIssueType, // API expects 'issue' not 'issue_type'
          'description': description,
          'user_id': userId ?? '',
        },
      );

      if (response.isSuccess) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report submitted successfully. Thank you!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Close dialog
        setState(() {
          _showReportDialog = false;
          _descriptionController.clear();
          _selectedIssueType = 'Incorrect Question';
          _descriptionLength = 0;
        });
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('📝 [REPORT ERROR] Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReport = false;
        });
      }
    }
  }

  Future<void> _savePaperMarks() async {
    // Prevent concurrent saves (if save is already in progress, skip)
    if (_isSavingMarks) {
      print('📊 [MARKS] Save already in progress, skipping duplicate call...');
      return;
    }

    setState(() {
      _isSavingMarks = true;
    });

    try {
      final userId = await UserSessionService.getUserId();
      final earnedMarks = _getEarnedMarks();
      final totalMarks = _getTotalMarks();
      final scorePercentage = _getScorePercentage();
      final duration = _totalTimeSeconds > _remainingSeconds 
          ? _totalTimeSeconds - _remainingSeconds 
          : 0; // Duration in seconds (ensure it's not negative)

      final durationValue = duration.toString();
      
      print('📊 [MARKS] Saving paper marks:');
      print('   - User ID: $userId');
      print('   - Paper ID: ${widget.paperId}');
      print('   - Earned Marks: $earnedMarks');
      print('   - Total Marks: $totalMarks');
      print('   - Score Percentage: ${scorePercentage.toStringAsFixed(2)}%');
      print('   - Duration: $duration seconds (${(duration / 60).toStringAsFixed(2)} minutes)');
      print('   - Duration string value: "$durationValue"');

      // Remove leading slash if present to avoid double slash in URL
      final endpoint = ApiEndpoints.postPaperMarks.startsWith('/')
          ? ApiEndpoints.postPaperMarks.substring(1)
          : ApiEndpoints.postPaperMarks;

      final requestBody = {
        'user_id': userId ?? '',
        'paper_id': widget.paperId,
        'score': earnedMarks.toStringAsFixed(2), // Save earned marks instead of percentage
        'duration': durationValue, // Duration in seconds (as string for API)
      };

      print('📊 [MARKS] Request body: $requestBody');

      final response = await _apiClient.post(
        endpoint,
        body: requestBody,
      );

      if (response.isSuccess) {
        print('📊 [MARKS] Successfully saved paper marks');
        
        // Reset timer values after successful save
        // This ensures duration doesn't accumulate if user continues or starts new attempt
        if (mounted) {
          setState(() {
            _totalTimeSeconds = 0;
            _remainingSeconds = 0;
            _timer?.cancel();
          });
        }
      } else {
        print('📊 [MARKS ERROR] Failed to save paper marks: ${response.error}');
        // Don't show error to user, just log it
      }
    } catch (e) {
      print('📊 [MARKS ERROR] Error saving paper marks: $e');
      // Don't show error to user, just log it
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMarks = false;
        });
      }
    }
  }
}
