# Optional ML Kit OCR script implementations are not bundled by the
# Latin-only text recognition dependency. The Flutter plugin references
# these optional classes when selecting a script at runtime.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
