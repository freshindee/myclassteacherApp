# Firebase Crashlytics Setup Guide

## What's Already Done ✅

1. **Dependencies Added**: `firebase_crashlytics: ^4.1.0` added to `pubspec.yaml`
2. **Android Configuration**: 
   - Added Crashlytics plugin to project-level `build.gradle.kts`
   - Added Crashlytics plugin to app-level `build.gradle.kts`
3. **Flutter Code**: 
   - Updated `main.dart` with Crashlytics initialization
   - Created `CrashlyticsService` utility class
4. **Error Handling**: Automatic crash reporting for Flutter errors and uncaught exceptions

## What You Need to Do 🔧

### 1. Enable Crashlytics in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `my-class-teacher-c833a`
3. In the left sidebar, click on **Crashlytics**
4. Click **Enable Crashlytics**
5. Follow the setup wizard

### 2. Download Updated google-services.json

After enabling Crashlytics:
1. Go to Project Settings (gear icon)
2. Download the updated `google-services.json` file
3. Replace the existing file in `android/app/google-services.json`

### 3. For iOS (if building for iOS)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your iOS project in Xcode
3. Add the following to your `ios/Runner/Info.plist`:

```xml
<key>FirebaseCrashlyticsCollectionEnabled</key>
<true/>
```

### 4. Test Crashlytics

You can test if Crashlytics is working by adding this code anywhere in your app:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Test crash
FirebaseCrashlytics.instance.crash();
```

## Usage Examples

### Log Custom Errors
```dart
import 'package:myclassteacher/core/services/crashlytics_service.dart';

final crashlytics = CrashlyticsService();

// Log an error
await crashlytics.logError('User authentication failed', error, stackTrace);

// Log a message
await crashlytics.log('User logged in successfully');

// Set custom keys
await crashlytics.setCustomKey('user_type', 'teacher');
await crashlytics.setCustomKey('app_version', '1.1.0');

// Set user ID
await crashlytics.setUserId('user123');
```

### In Your Bloc Classes
```dart
try {
  // Your business logic
} catch (e, stackTrace) {
  await CrashlyticsService().logError('Failed to load data', e, stackTrace);
  // Handle error
}
```

## Build Commands

After setup, use these commands to build:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## Troubleshooting

1. **Crashlytics not showing data**: Wait 5-10 minutes for data to appear
2. **Build errors**: Make sure you've downloaded the updated `google-services.json`
3. **iOS issues**: Ensure `GoogleService-Info.plist` is added to Xcode project

## Next Steps

1. Run `flutter pub get` to install the new dependency
2. Enable Crashlytics in Firebase Console
3. Download and replace the configuration files
4. Test with a sample crash
5. Monitor crashes in Firebase Console

## Security Note

Crashlytics automatically collects crash reports and app usage data. Make sure this complies with your privacy policy and user consent requirements.
