import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as px;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';
import 'scan_service.dart';

class DocumentTextExtractor {
  /// Extracted text by stored file path. Imported files get a unique name
  /// and are never edited, so a path always means the same content. This
  /// keeps the assistant from re-reading every file on every question.
  static final Map<String, String> _cache = {};

  /// Drops a cached text, e.g. after the file was deleted for good.
  static void forget(String path) => _cache.remove(path);

  /// Most pages read from a scanned PDF, to keep it quick and the text within
  /// the AI's context limit.
  static const maxOcrPages = 8;

  /// Renders the pages of a scanned PDF and reads their text on the device.
  /// Returns an empty string if nothing could be read.
  static Future<String> _ocrPdf(String path) async {
    final pages = <String>[];
    px.PdfDocument? document;
    try {
      document = await px.PdfDocument.openFile(path);
      final count = math.min(document.pagesCount, maxOcrPages);
      final dir = await getTemporaryDirectory();
      for (var i = 1; i <= count; i++) {
        final page = await document.getPage(i);
        try {
          // About 1600px wide is enough for printed text and keeps memory low.
          final scale = 1600 / page.width;
          final image = await page.render(
              width: page.width * scale,
              height: page.height * scale,
              format: px.PdfPageImageFormat.jpeg,
              backgroundColor: '#ffffff');
          if (image == null) continue;
          final file = File(
              '${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}_$i.jpg');
          await file.writeAsBytes(image.bytes, flush: true);
          try {
            pages.add(await ScanService.recognize(file.path));
          } finally {
            await file.delete();
          }
        } finally {
          await page.close();
        }
      }
    } catch (_) {
      return '';
    } finally {
      await document?.close();
    }
    return joinScanPages(pages);
  }

  static Future<String> extract(String path, String type) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('The original file is no longer available on this device. Please upload it again.');
    final cached = _cache[path];
    if (cached != null) return cached;
    final bytes = await file.readAsBytes();
    final ext = type.toUpperCase();
    String text;
    if (ext == 'PDF') {
      final pdf = sf.PdfDocument(inputBytes: bytes);
      try { text = sf.PdfTextExtractor(pdf).extractText(); }
      finally { pdf.dispose(); }
      // A scanned PDF has no text layer: read its pages as images instead.
      if (text.trim().length < 40) {
        final ocr = await _ocrPdf(path);
        if (ocr.isNotEmpty) {
          text = '[This text was read from scanned pages and may contain recognition errors.]\n$ocr';
        }
      }
    } else if (ext == 'DOCX') {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = archive.files.where((f) => f.name == 'word/document.xml').toList();
      if (entries.isEmpty) throw Exception('Could not find the text body inside this DOCX file.');
      final entry = entries.first;
      final xml = XmlDocument.parse(utf8.decode(entry.content as List<int>, allowMalformed: true));
      text = xml.descendants.whereType<XmlElement>()
        .where((e) => e.name.local == 't').map((e) => e.innerText).join(' ');
    } else if (ext == 'TXT') {
      text = utf8.decode(bytes, allowMalformed: true);
    } else if (ext == 'SCAN') {
      text = '[This text was read from photos and may contain recognition errors.]\n'
          '${utf8.decode(bytes, allowMalformed: true)}';
    } else if (ext == 'RTF') {
      text = utf8.decode(bytes, allowMalformed: true)
        .replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), ' ')
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), ' ')
        .replaceAll(RegExp(r'\\\\'), ' ');
    } else {
      throw Exception('Legacy .doc files are not supported yet. Save this file as .docx or PDF and upload it again.');
    }
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (text.isEmpty) throw Exception('No readable text was extracted from this file.');
    if (text.length > 65000) text = '${text.substring(0, 65000)}\n[Document truncated for analysis due to context limits.]';
    _cache[path] = text;
    return text;
  }
}
