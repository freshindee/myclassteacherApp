import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// Log a custom error to Crashlytics
  Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
      );
    } catch (e) {
      // Fallback if Crashlytics fails
      print('Failed to log to Crashlytics: $e');
    }
  }

  /// Log a custom message to Crashlytics
  Future<void> log(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      // Fallback if Crashlytics fails
      print('Failed to log to Crashlytics: $e');
    }
  }

  /// Set a custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      // Fallback if Crashlytics fails
      print('Failed to set custom key in Crashlytics: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserId(userId);
    } catch (e) {
      // Fallback if Crashlytics fails
      print('Failed to set user ID in Crashlytics: $e');
    }
  }

  /// Enable/disable Crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      // Fallback if Crashlytics fails
      print('Failed to set Crashlytics collection enabled: $e');
    }
  }
}
