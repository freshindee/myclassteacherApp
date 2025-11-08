# Building App Bundle with Signing Key

This guide explains how to build a signed app bundle (AAB) for your MyClassTeacher Flutter app.

## Prerequisites

- Flutter SDK installed and configured
- Android SDK with build tools
- Java Development Kit (JDK) 11 or higher
- `keytool` command available in your PATH

## Setup

### 1. Configure Signing Properties

Edit `android/gradle.properties` and set your actual keystore passwords:

```properties
# Keystore configuration for app signing
MYAPP_UPLOAD_STORE_FILE=myclassteacher.keystore
MYAPP_UPLOAD_KEY_ALIAS=myclassteacher
MYAPP_UPLOAD_STORE_PASSWORD=your_actual_store_password
MYAPP_UPLOAD_KEY_PASSWORD=your_actual_key_password
```

**⚠️ IMPORTANT**: Replace the placeholder passwords with strong, secure passwords and keep them safe!

### 2. Generate Keystore

The keystore will be automatically generated when you run the build tasks. If you want to generate it manually:

```bash
cd android/app
./gradlew generateKeystore
```

## Building

### Build Signed App Bundle (Recommended for Play Store)

```bash
cd android/app
./gradlew buildSignedBundle
```

This will:
- Generate the keystore if it doesn't exist
- Build a signed app bundle (.aab file)
- Show the bundle size and location

### Build Signed APK

```bash
cd android/app
./gradlew buildSignedApk
```

This will:
- Generate the keystore if it doesn't exist
- Build a signed APK (.apk file)
- Show the APK size and location

### Build from Flutter CLI

You can also build using Flutter commands:

```bash
# Build app bundle
flutter build appbundle --release

# Build APK
flutter build apk --release
```

## Output Files

- **App Bundle**: `android/app/build/outputs/bundle/release/app-release.aab`
- **APK**: `android/app/build/outputs/apk/release/app-release.apk`

## Keystore Security

### Store Location
The keystore file is created in `android/app/myclassteacher.keystore`

### Backup Your Keystore
**CRITICAL**: Keep a secure backup of your keystore file and passwords. If you lose them:
- You cannot update your app on the Play Store
- You'll need to publish a new app with a different package name

### Recommended Security Practices
1. Use strong, unique passwords
2. Store keystore file in a secure location
3. Document keystore details in a secure password manager
4. Never commit keystore passwords to version control

## Troubleshooting

### Common Issues

1. **Keystore not found**
   - Run `./gradlew generateKeystore` first
   - Check if the keystore file exists in `android/app/`

2. **Password incorrect**
   - Verify passwords in `android/gradle.properties`
   - Ensure no extra spaces or characters

3. **Build fails**
   - Clean the project: `./gradlew clean`
   - Check Flutter doctor: `flutter doctor`
   - Verify Android SDK installation

### Verification

To verify your keystore:

```bash
keytool -list -v -keystore android/app/myclassteacher.keystore
```

## Play Store Upload

1. Build the app bundle: `./gradlew buildSignedBundle`
2. Upload the `.aab` file to Google Play Console
3. The app bundle will be automatically signed by Google Play

## Size Optimization

The build configuration includes several optimizations:
- Resource shrinking enabled
- Code obfuscation with ProGuard
- PNG compression
- ABI filtering (arm64-v8a, armeabi-v7a only)
- Resource language filtering (English and Sinhala only)

## Commands Summary

```bash
# Generate keystore
./gradlew generateKeystore

# Build signed app bundle
./gradlew buildSignedBundle

# Build signed APK
./gradlew buildSignedApk

# Clean and rebuild
./gradlew cleanAndRebuild

# Analyze APK size
./gradlew analyzeApkSize
```

## Support

If you encounter issues:
1. Check the error messages in the build output
2. Verify your keystore configuration
3. Ensure all prerequisites are met
4. Check Flutter and Android SDK versions

