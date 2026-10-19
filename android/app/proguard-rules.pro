# Flutter engine & embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign-In / Play Services (Drive sync)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Play Core (deferred components direferensikan Flutter engine, tidak dipakai)
-dontwarn com.google.android.play.core.**

# Kotlin coroutines (bawaan plugin)
-dontwarn kotlinx.coroutines.**
