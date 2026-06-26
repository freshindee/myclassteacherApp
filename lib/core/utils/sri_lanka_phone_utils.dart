/// Sri Lanka mobile: national format `07XXXXXXXX` (10 digits).
///
/// Accepts common inputs: `0771234567`, `771234567`, `+94 77 123 4567`, `0094771234567`.
/// Firestore student document id is typically these digits (often 10 digits including leading `0`).
class SriLankaPhoneUtils {
  SriLankaPhoneUtils._();

  static final RegExp _digitsOnly = RegExp(r'\D');

  /// Allowed Sri Lanka mobile operator prefixes for student registration.
  static const List<String> registrationMobilePrefixes = [
    '070',
    '071',
    '072',
    '074',
    '075',
    '076',
    '077',
    '078',
  ];

  /// National mobile: 10 digits, starts with `07`, then 8 more digits.
  static bool isValidLocalTenDigits(String digits) {
    if (digits.length != 10) return false;
    return RegExp(r'^07\d{8}$').hasMatch(digits);
  }

  /// Returns local mobile as **10 digits** including leading `0`, or `null` if invalid.
  static String? normalizeToLocalTenDigits(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'[\s\-\.()]'), '');
    if (s.startsWith('+94')) {
      s = '0${s.substring(3)}';
    } else if (s.toLowerCase().startsWith('0094')) {
      s = '0${s.substring(4)}';
    } else if (RegExp(r'^94\d{9}$').hasMatch(s)) {
      s = '0${s.substring(2)}';
    }
    final digits = s.replaceAll(_digitsOnly, '');
    if (digits.isEmpty) return null;
    if (digits.length == 9 && digits.startsWith('7')) {
      final candidate = '0$digits';
      return isValidLocalTenDigits(candidate) ? candidate : null;
    }
    if (digits.length == 10 && digits.startsWith('07')) {
      return isValidLocalTenDigits(digits) ? digits : null;
    }
    return null;
  }

  /// `null` if valid; otherwise a short error message for forms.
  static String? validateMobileField(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (normalizeToLocalTenDigits(raw) == null) {
      return 'Enter a valid Sri Lanka mobile (e.g. 0771234567 or +94 77 123 4567)';
    }
    return null;
  }

  /// Registration: 10 digits with an allowed operator prefix (`070`–`078`, excluding `073`/`079`).
  static bool isValidRegistrationLocalTenDigits(String digits) {
    if (digits.length != 10) return false;
    return registrationMobilePrefixes.contains(digits.substring(0, 3));
  }

  /// Registration: local format only. Rejects `+94`, `0094`, and `94…` prefixes.
  static String? normalizeRegistrationMobile(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'[\s\-\.()]'), '');
    if (s.startsWith('+') ||
        s.toLowerCase().startsWith('0094') ||
        RegExp(r'^94\d').hasMatch(s)) {
      return null;
    }
    final digits = s.replaceAll(_digitsOnly, '');
    if (digits.length == 10 && isValidRegistrationLocalTenDigits(digits)) {
      return digits;
    }
    return null;
  }

  static String get _registrationPrefixHint =>
      'Use 070, 071, 072, 074, 075, 076, 077, or 078';

  /// Registration form validation — must start with `0`, no country code.
  static String? validateRegistrationMobileField(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Phone number is required';
    }
    final compact = raw.trim().replaceAll(RegExp(r'[\s\-\.()]'), '');
    if (compact.startsWith('+') ||
        compact.toLowerCase().startsWith('0094') ||
        RegExp(r'^94\d').hasMatch(compact.replaceAll(_digitsOnly, ''))) {
      return 'Use local format starting with 0 ($_registrationPrefixHint)';
    }
    final digits = compact.replaceAll(_digitsOnly, '');
    if (digits.length == 10 &&
        digits.startsWith('07') &&
        !isValidRegistrationLocalTenDigits(digits)) {
      return 'Invalid operator prefix. $_registrationPrefixHint';
    }
    if (normalizeRegistrationMobile(raw) == null) {
      return 'Enter a valid 10-digit mobile ($_registrationPrefixHint)';
    }
    return null;
  }

  /// Tries document ids used in the wild: full `07…` then legacy `77…` (9 digits).
  static List<String> candidateStudentDocumentIds(String localTenDigits) {
    if (!isValidLocalTenDigits(localTenDigits)) return [];
    return [localTenDigits, localTenDigits.substring(1)];
  }
}
