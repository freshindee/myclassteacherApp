# Flutter/Dart ProGuard rules
# Keep Flutter's generated classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.annotation.Keep { *; }
-keep class androidx.annotation.Keep$*
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference
-keep public class com.android.vending.licensing.ILicensingService

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove debug information
-assumenosideeffects class android.util.Log {
    public static *** isLoggable(java.lang.String, int);
}

# Remove System.out calls
-assumenosideeffects class java.lang.System {
    public static void out;
    public static void err;
}

# Remove printStackTrace calls
-assumenosideeffects class java.lang.Throwable {
    public void printStackTrace();
    public void printStackTrace(java.io.PrintStream);
    public void printStackTrace(java.io.PrintWriter);
}

# Add any additional rules for libraries you use below

# Enhanced ProGuard optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Advanced size reduction optimizations
-optimizations !code/removal/arithmetic,!code/removal/assign,!code/removal/cast,!code/removal/checkcast,!code/removal/instanceof,!code/removal/newarray,!code/removal/newinstance,!code/removal/return,!code/removal/throw,!code/removal/unused
-optimizationpasses 8
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Aggressive code shrinking
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep custom application class
-keep class com.fusionlkitsolution.myclassteacher.MyApplication { *; }

# Keep MainActivity
-keep class com.fusionlkitsolution.myclassteacher.MainActivity { *; }

# Aggressive code removal for unused methods
-assumenosideeffects class * {
    @androidx.annotation.Keep <methods>;
}

# Remove unused fields
-assumenosideeffects class * {
    @androidx.annotation.Keep <fields>;
}

# Remove unused constructors
-assumenosideeffects class * {
    @androidx.annotation.Keep <init>(...);
}

# Firebase specific rules
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# YouTube Player rules
-keep class com.pierfrancescosoffritti.androidyoutubeplayer.** { *; }
-keep class com.google.android.youtube.** { *; }

# Carousel Slider rules
-keep class com.synnapps.carouselview.** { *; }

# Syncfusion PDF rules
-keep class com.syncfusion.** { *; }

# Advanced resource shrinking
-keep class **.R$* {
    public static <fields>;
}

# Remove unused resources
-assumenosideeffects class android.content.res.Resources {
    public static *** getIdentifier(java.lang.String, java.lang.String, java.lang.String);
}

# Remove unused string resources
-assumenosideeffects class android.content.res.Resources {
    public java.lang.String getString(int);
    public java.lang.String getString(int, java.lang.Object...);
}

# Play Core and deferred components (from missing_rules.txt)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn java.lang.reflect.AnnotatedType 