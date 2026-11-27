import 'package:flutter/services.dart';

/// A file another app shared to DocuMind, already copied into the app's
/// cache by the Android side.
class SharedFile {
  final String path;
  final String name;
  const SharedFile(this.path, this.name);
}

/// Document type for a file name, or null when the app cannot read it.
String? documentTypeFor(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (name.substring(dot + 1).toLowerCase()) {
    'pdf' => 'PDF',
    'docx' => 'DOCX',
    'txt' => 'TXT',
    'rtf' => 'RTF',
    _ => null,
  };
}

/// Whether a shared file is a photo to be read with the text scanner.
bool isImageName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return false;
  return const {'png', 'jpg', 'jpeg', 'webp', 'heic'}
      .contains(name.substring(dot + 1).toLowerCase());
}

/// "512 KB" / "1.4 MB".
String formatFileSize(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(0)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

List<SharedFile> parseSharedFiles(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map && item['path'] is String && item['name'] is String)
        SharedFile(item['path'] as String, item['name'] as String),
  ];
}

/// Receives files shared into the app from other apps (Android).
/// On other platforms, and in tests, nothing arrives.
abstract final class ShareIntentService {
  static const _channel = MethodChannel('documind/share');

  /// Files that opened the app ("Share to DocuMind" while it was closed).
  static Future<List<SharedFile>> takeInitial() async {
    try {
      return parseSharedFiles(await _channel.invokeMethod<List<dynamic>>('takeInitial'));
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  /// Files shared while the app is already open.
  static void listen(void Function(List<SharedFile> files) onFiles) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') onFiles(parseSharedFiles(call.arguments));
    });
  }

  static void stop() => _channel.setMethodCallHandler(null);
}
