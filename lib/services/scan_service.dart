import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Fewest characters a scan must yield to be kept. Anything shorter is almost
/// always a blurry or empty photo, not a document.
const minScanTextLength = 20;

/// Joins the text of scanned pages. With several pages each one is labelled,
/// so the AI (and the reader) can tell where a page starts. Empty pages are
/// dropped.
String joinScanPages(List<String> pages) {
  final cleaned =
      pages.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (cleaned.length <= 1) return cleaned.join();
  return [
    for (var i = 0; i < cleaned.length; i++)
      '--- Page ${i + 1} ---\n${cleaned[i]}',
  ].join('\n\n');
}

/// Default name for a scan, e.g. "Scan 2026-11-26 21:30".
String scanName(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'Scan ${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)}';
}

/// Reads text from photos with Google ML Kit, entirely on the device.
///
/// Only Latin-script text is recognized (English, French, Spanish...).
/// ML Kit has no Arabic model.
abstract final class ScanService {
  static Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
