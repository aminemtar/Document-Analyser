import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:xml/xml.dart';

class DocumentTextExtractor {
  static Future<String> extract(String path, String type) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('The original file is no longer available on this device. Please upload it again.');
    final bytes = await file.readAsBytes();
    final ext = type.toUpperCase();
    String text;
    if (ext == 'PDF') {
      final pdf = sf.PdfDocument(inputBytes: bytes);
      try { text = sf.PdfTextExtractor(pdf).extractText(); }
      finally { pdf.dispose(); }
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
    return text;
  }
}
