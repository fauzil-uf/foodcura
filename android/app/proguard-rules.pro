# Suppress warnings for optional / deferred components in Flutter
-dontwarn com.google.android.play.core.**

# Suppress warnings for Desugaring & Java compatibility
-dontwarn java.lang.invoke.**
-dontwarn java.lang.ProcessHandle**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat** { *; }
