/// API endpoints constants
/// Centralized location for all API endpoints used in the app
class ApiEndpoints {
  // Base URL for the exam API
  static const String examApiBaseUrl = 'https://darkslategrey-lemur-524608.hostingersite.com/papers';

  // School content (video, pdf_notes, zoom_classes) - at papers/get_school_content.php (no api/ folder)
  static const String getSchoolContent = 'get_school_content.php';

  // Papers endpoints (paths relative to base URL which already includes /papers; no api/ folder)
  static const String papersSubjects = 'subjects.php';
  static const String papersChapters = 'get_chapters.php';
  static const String papersList = 'get_paper_list.php';
  static const String papersQuestions = 'get_questions_list.php';
  static const String reportQuestion = 'post_questions_error.php';
  static const String postPaperMarks = 'post_paper_marks.php';
  static const String examHistory = 'get_exam_history.php';

  // Full URLs (base has no trailing slash; path has no leading slash)
  static String get papersSubjectsUrl => '$examApiBaseUrl/$papersSubjects';
  static String get papersChaptersUrl => '$examApiBaseUrl/$papersChapters';
  static String get papersListUrl => '$examApiBaseUrl/$papersList';
  static String get papersQuestionsUrl => '$examApiBaseUrl/$papersQuestions';
  static String get reportQuestionUrl => '$examApiBaseUrl/$reportQuestion';
  static String get postPaperMarksUrl => '$examApiBaseUrl/$postPaperMarks';
}
