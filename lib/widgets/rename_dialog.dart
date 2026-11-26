import 'package:flutter/material.dart';

/// Asks for a new document name. Returns the trimmed name, or null when the
/// user cancels, dismisses the dialog or leaves the field empty.
Future<String?> showRenameDialog(BuildContext context, String current) =>
    showDialog<String>(
        context: context, builder: (_) => _RenameDialog(current: current));

class _RenameDialog extends StatefulWidget {
  final String current;
  const _RenameDialog({required this.current});
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

// The dialog owns its controller so it is disposed only after the dialog's
// closing animation has finished.
class _RenameDialogState extends State<_RenameDialog> {
  late final controller = TextEditingController(text: widget.current);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = controller.text.trim();
    Navigator.of(context).pop(name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      );
}
