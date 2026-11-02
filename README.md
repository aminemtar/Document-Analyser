# DocuMind AI

A premium blue Flutter document workspace with real local text extraction and AI-powered analysis.

## Run locally

```bash
git clone https://github.com/aminemtar/Document-Analyser.git
cd Document-Analyser
flutter create . --platforms=android,ios
flutter pub get
```

Set your OpenRouter key for a local test run:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY
```

Optional: choose a specific OpenRouter model:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY --dart-define=OPENROUTER_MODEL=openrouter/free
```

Get a key from [OpenRouter](https://openrouter.ai/keys). The default model route is `openrouter/free`, which routes to an available free model. Availability and rate limits depend on OpenRouter.

## Implemented

- PDF text extraction (text-based PDFs)
- DOCX text extraction
- TXT and basic RTF text extraction
- AI analysis through OpenRouter: summary, key details, potential risks, and action items
- Analysis results saved locally with each document
- Local document library and navigation

## Current limitations

- Scanned/image-only PDFs need OCR; they are detected as having no readable text and are not silently analyzed.
- Legacy `.doc` files are not supported; convert them to `.docx` or PDF.
- The assistant chat and document comparison screens are still UI previews; they are not connected to the AI service yet.
- OpenRouter key passed with `--dart-define` is embedded in the app binary. This is suitable only for local testing. For a public release, route requests through a secure backend and keep the key server-side.
- AI-generated risk notes are not legal, financial, or professional advice. Verify important findings against the source document.

## Android

The app uses Android compile SDK 36. Ensure Android SDK Platform 36 is installed in Android Studio.
