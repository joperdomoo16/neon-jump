# Proguard rules to prevent R8 from stripping/obfuscating WorkManager classes.
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
