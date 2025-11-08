# Quick Start: Build App Bundle

## 🚀 Fast Track (3 Steps)

### 1. Set Passwords
Edit `android/gradle.properties` and change these lines:
```properties
MYAPP_UPLOAD_STORE_PASSWORD=your_actual_store_password
MYAPP_UPLOAD_KEY_PASSWORD=your_actual_key_password
```

### 2. Build App Bundle
```bash
./build_app.sh bundle
```

### 3. Find Your Bundle
The signed app bundle will be at:
`android/app/build/outputs/bundle/release/app-release.aab`

## 📱 Alternative: Build APK
```bash
./build_app.sh apk
```

## 🔧 What Happens Automatically
- ✅ Keystore generation
- ✅ App signing
- ✅ Size optimization
- ✅ Bundle/APK creation
- ✅ Size reporting

## 🆘 Need Help?
- Run `./build_app.sh help` for all options
- Check `BUILD_APP_BUNDLE.md` for detailed guide
- Run `./build_app.sh check` to verify setup

## 🎯 For Play Store
Use the `.aab` file (app bundle) - it's smaller and more efficient!

