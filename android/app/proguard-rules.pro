# Optional ML Kit OCR script implementations are not bundled by the
# Latin-only text recognition dependency. The Flutter plugin references
# these optional classes when selecting a script at runtime.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# WorkManager creates its Room database implementation reflectively during
# AndroidX Startup initialization. Preserve the generated implementation and
# its Room schema/model classes in minified release builds.
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.model.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class * { *; }
