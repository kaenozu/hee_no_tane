# Flutter: keep everything
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep share_plus
-keep class com.share_plus.** { *; }

# Keep url_launcher
-keep class com.url_launcher.** { *; }

# Keep SharedPreferences
-keep class android.content.SharedPreferences { *; }

# General: keep model classes
-keep class com.heenotane.hee_no_tane_app.** { *; }

# Flutter engine references Play Store deferred component classes even when the
# app does not use deferred components. They are optional for this build.
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
