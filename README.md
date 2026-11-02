# DocuMind AI

A premium blue Flutter workspace for organizing and understanding documents.

## Current app screens

- Home dashboard with document stats and recent files
- Document library with search and file-type filters
- Analysis workspace with overview, key details, risk review, and action items
- AI assistant chat interface
- Insights dashboard
- Document comparison workspace
- Profile and settings

## Run locally

The repository starts with the Flutter app source. Generate the native Android and iOS runner projects once:

```bash
git clone https://github.com/aminemtar/Document-Analyser.git
cd Document-Analyser
flutter create . --platforms=android,ios
flutter pub get
flutter run
```

To run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Current implementation status

The interface is runnable and includes local document selection (PDF, DOC, DOCX, TXT and RTF), a locally persisted document library, navigation, search/filtering, and interactive chat/comparison screens.

**Important:** AI responses and analysis content are currently demo placeholders. The app does not yet extract text from PDFs/Word files or send documents to an AI model. Connect a secure backend and an AI provider before treating analysis, risk flags, or comparisons as real results. Never put private API keys directly in the Flutter client.

## Stack

- Flutter / Dart
- Material 3
- Google Fonts (Inter)
- File Picker
- Shared Preferences
