import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/scan_service.dart';
import '../theme/app_theme.dart';

/// Lets the user take photos (one or more pages) or pick them from the
/// gallery, reads their text on the device, and returns one text per page.
/// Returns an empty list when the user cancels before any page is read.
///
/// Errors from the camera or the text reader propagate to the caller.
Future<List<String>> scanPages(
    BuildContext context, ImageSource source) async {
  final picker = ImagePicker();
  final pages = <String>[];

  if (source == ImageSource.gallery) {
    final files = await picker.pickMultiImage(maxWidth: 2400, imageQuality: 90);
    if (files.isEmpty || !context.mounted) return pages;
    final texts = await _withProgress(context, () async {
      final out = <String>[];
      for (final file in files) {
        out.add(await ScanService.recognize(file.path));
      }
      return out;
    });
    return texts;
  }

  while (true) {
    final shot = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 2400, imageQuality: 90);
    if (shot == null || !context.mounted) break;
    pages.add(await _withProgress(
        context, () => ScanService.recognize(shot.path)));
    if (!context.mounted) break;
    final another = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Page ${pages.length} scanned'),
        content: const Text('Add another page to this document?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Done')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add page')),
        ],
      ),
    );
    if (another != true) break;
  }
  return pages;
}

/// Runs [task] behind a small non-dismissible "Reading text" dialog.
Future<T> _withProgress<T>(
    BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: blue)),
          const SizedBox(width: 18),
          const Expanded(child: Text('Reading text…')),
        ]),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}
