class MonthUtils {
  static const List<String> monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  /// Convert month number (1-12) to month name
  static String getMonthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) {
      throw ArgumentError('Month number must be between 1 and 12');
    }
    return monthNames[monthNumber];
  }

  /// Convert month name to month number (1-12)
  static int getMonthNumber(String monthName) {
    final index = monthNames.indexWhere(
      (name) => name.toLowerCase() == monthName.toLowerCase()
    );
    if (index == -1) {
      throw ArgumentError('Invalid month name: $monthName');
    }
    return index;
  }

  /// Get all month names for dropdown
  static List<String> getAllMonthNames() {
    return monthNames.sublist(1); // Remove empty first element
  }

  /// Check if a string is a valid month name
  static bool isValidMonthName(String monthName) {
    return monthNames.any((name) => name.toLowerCase() == monthName.toLowerCase());
  }

  /// Check if a number is a valid month number
  static bool isValidMonthNumber(int monthNumber) {
    return monthNumber >= 1 && monthNumber <= 12;
  }
} 