# Proguard rules to prevent R8 from stripping/obfuscating WorkManager classes.
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class com.google.android.play.core.** { *; }

# flutter_local_notifications: serializa las notificaciones programadas con Gson
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
