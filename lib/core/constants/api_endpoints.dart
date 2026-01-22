/// API endpoints constants
/// Centralized location for all API endpoints used in the app
class ApiEndpoints {
  // Base URL for the exam API
  static const String examApiBaseUrl = 'https://silver-wombat-561308.hostingersite.com/api';

  // Papers endpoints
  static const String papersSubjects = '/papers/subjects.php';
  static const String papersChapters = '/papers/get_chapters.php';
  static const String papersList = '/papers/get_paper_list.php';
  static const String papersQuestions = '/papers/get_questions_list.php';
  static const String reportQuestion = '/papers/post_questions_error.php';
  static const String postPaperMarks = '/papers/post_paper_marks.php';
  static const String examHistory = '/papers/get_exam_history.php';
  
  // Full URLs
  static String get papersSubjectsUrl => '$examApiBaseUrl$papersSubjects';
  static String get papersChaptersUrl => '$examApiBaseUrl$papersChapters';
  static String get papersListUrl => '$examApiBaseUrl$papersList';
  static String get papersQuestionsUrl => '$examApiBaseUrl$papersQuestions';
  static String get reportQuestionUrl => '$examApiBaseUrl$reportQuestion';
  static String get postPaperMarksUrl => '$examApiBaseUrl$postPaperMarks';
}
