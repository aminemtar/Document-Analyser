import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../l10n/l10n.dart';
import 'package:http/http.dart' as http;

/// The text carried by one line of a streamed (server-sent events) reply, or
/// null for lines that carry none (comments, blank lines, the final DONE).
String? parseSseDelta(String line) {
  if (!line.startsWith('data:')) return null;
  final payload = line.substring(5).trim();
  if (payload.isEmpty || payload == '[DONE]') return null;
  try {
    final json = jsonDecode(payload);
    final content = json['choices']?[0]?['delta']?['content'];
    return content is String ? content : null;
  } catch (_) {
    return null;
  }
}

class OpenRouterDocumentAI {
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '';
  static String get _model =>
      dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['OPENROUTER_MODEL']!.trim()
          : 'openrouter/free';

  static Future<String> _complete({
    required String system,
    required String user,
    double temperature = 0.2,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key is missing. Add OPENROUTER_API_KEY to the .env file in the project root. For production, move AI calls to a secure backend.');
    }
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/aminemtar/Document-Analyser',
        'X-Title': 'DocuMind AI',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    ).timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI service returned ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final content = payload['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('The AI service returned an empty response.');
    }
    return content.trim();
  }

  static Map<String, dynamic> _decodeJson(String content) {
    final cleaned = content
        .replaceFirst(RegExp(r'^\x60\x60\x60(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*\x60\x60\x60$'), '');
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The AI response was not valid structured JSON. Please run it again.');
    }
  }

  static Future<Map<String, dynamic>> analyze({
    required String fileName,
    required String fileType,
    required String text,
  }) async {
    final content = await _complete(
      system: 'You are a careful document analyst. Only report facts supported by the supplied text. Never invent names, dates, amounts, clauses or risks. If something is absent or unclear, say so. Return valid JSON only with keys: document_type (string), summary (string), key_details (array of strings), risks (array of objects with level, title, detail), action_items (array of strings), confidence_notes (string), review_level (integer 0-100 showing how much attention the document needs, based only on the risks you found), important_dates (array of objects with label, date, note; date is YYYY-MM-DD only when an exact date is written in the text, otherwise null), amounts (array of objects with label and value, value exactly as written in the text), suggested_questions (array of 3 short questions a reader could ask about this document). Separate factual observations from recommendations. Do not present legal conclusions as professional advice. Write every human-readable text value in ${L10n.aiLanguageName} (keep the JSON keys in English and quote document text as written).',
      user: 'Analyze this real uploaded document. Filename: $fileName. Format: $fileType.\n\nDOCUMENT TEXT:\n$text',
    );
    return _decodeJson(content);
  }

  static Future<String> ask({
    required String question,
    required List<Map<String, String>> documents,
  }) {
    final context = documents.map((d) =>
      'FILE: ${d['name']}\nCONTENT:\n${d['text']}'
    ).join('\n\n--- NEXT DOCUMENT ---\n\n');
    return _complete(
      system: 'You are DocuMind, a precise assistant that answers questions using only the provided uploaded document text. Cite the source filename when possible. If the answer is not present in the supplied files, say clearly that the uploaded documents do not contain enough information. Never invent facts. Be concise but useful. Reply in the language of the question; if it is unclear, reply in ${L10n.aiLanguageName}.',
      user: 'QUESTION:\n$question\n\nUPLOADED DOCUMENTS:\n$context',
      temperature: 0.1,
    );
  }

  /// Like [ask], but yields the answer piece by piece as it is written.
  static Stream<String> askStream({
    required String question,
    required List<Map<String, String>> documents,
  }) async* {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key is missing. Add OPENROUTER_API_KEY to the .env file in the project root.');
    }
    final context = documents.map((d) =>
      'FILE: ${d['name']}\nCONTENT:\n${d['text']}'
    ).join('\n\n--- NEXT DOCUMENT ---\n\n');
    final client = http.Client();
    try {
      final request = http.Request(
          'POST', Uri.parse('https://openrouter.ai/api/v1/chat/completions'))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'HTTP-Referer': 'https://github.com/aminemtar/Document-Analyser',
          'X-Title': 'DocuMind AI',
        })
        ..body = jsonEncode({
          'model': _model,
          'temperature': 0.1,
          'stream': true,
          'messages': [
            {
              'role': 'system',
              'content': 'You are DocuMind, a precise assistant that answers questions using only the provided uploaded document text. Cite the source filename when possible. If the answer is not present in the supplied files, say clearly that the uploaded documents do not contain enough information. Never invent facts. Be concise but useful. Reply in the language of the question; if it is unclear, reply in ${L10n.aiLanguageName}.'
            },
            {
              'role': 'user',
              'content': 'QUESTION:\n$question\n\nUPLOADED DOCUMENTS:\n$context'
            },
          ],
        });
      final response =
          await client.send(request).timeout(const Duration(seconds: 90));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw Exception('AI service returned ${response.statusCode}: ${body.length > 500 ? body.substring(0, 500) : body}');
      }
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final piece = parseSseDelta(line);
        if (piece != null && piece.isNotEmpty) yield piece;
      }
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> compare({
    required String firstName,
    required String firstText,
    required String secondName,
    required String secondText,
  }) async {
    final content = await _complete(
      system: 'You compare two real documents carefully. Only report differences supported by the supplied text. Do not assume that missing text means a clause was removed unless the comparison supports that conclusion. Return valid JSON only with keys: summary (string), similarities (array of strings), differences (array of objects with topic, document_a, document_b, significance), changed_dates_or_amounts (array of strings), review_points (array of strings). State when a value is not found. Do not give professional legal advice. Write every human-readable text value in ${L10n.aiLanguageName} (keep the JSON keys in English).',
      user: 'Compare these two uploaded documents.\n\nDOCUMENT A: $firstName\n$firstText\n\nDOCUMENT B: $secondName\n$secondText',
    );
    return _decodeJson(content);
  }
}
