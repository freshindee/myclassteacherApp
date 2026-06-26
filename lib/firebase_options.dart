import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase options for this app (from Firebase Console → Web app).
///
/// Web values match the JS SDK `firebaseConfig` you registered. You can still
/// override any field at build time with `--dart-define=FIREBASE_WEB_API_KEY=...`
/// (same keys as before).
class DefaultFirebaseOptions {
  // --- Web (my-class-teacher-c833a) ---
  static const String _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyAxUDevK7n6Q6RCXFoldPSrpkoIdY50FxM',
  );
  static const String _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:287250779744:web:9257858be73326477e7d05',
  );
  static const String _webMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '287250779744',
  );
  static const String _webProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'my-class-teacher-c833a',
  );
  static const String _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'my-class-teacher-c833a.firebaseapp.com',
  );
  static const String _webStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'my-class-teacher-c833a.firebasestorage.app',
  );
  static const String _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: 'G-64XVN34LZ0',
  );

  static bool get isWebConfigured {
    return _webApiKey.isNotEmpty &&
        _webAppId.isNotEmpty &&
        _webMessagingSenderId.isNotEmpty &&
        _webProjectId.isNotEmpty;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _webMessagingSenderId,
        projectId: _webProjectId,
        authDomain: _webAuthDomain.isEmpty ? null : _webAuthDomain,
        storageBucket: _webStorageBucket.isEmpty ? null : _webStorageBucket,
        measurementId: _webMeasurementId.isEmpty ? null : _webMeasurementId,
      );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }
}
