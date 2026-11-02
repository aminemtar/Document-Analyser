# DocuMind AI

A premium blue Flutter document workspace with local text extraction and AI-powered analysis.

## Setup

```bash
git clone https://github.com/aminemtar/Document-Analyser.git
cd Document-Analyser
flutter create . --platforms=android,ios
cp .env.example .env
```

Open the new `.env` file and add your OpenRouter API key:

```env
OPENROUTER_API_KEY=your_openrouter_api_key_here
OPENROUTER_MODEL=openrouter/free
```

Then run:

```bash
flutter pub get
flutter run
```

Get an API key from [OpenRouter](https://openrouter.ai/keys). The default model route is `openrouter/free`; availability and rate limits depend on OpenRouter.

## Implemented

- PDF text extraction (text-based PDFs)
- DOCX text extraction
- TXT and basic RTF text extraction
- OpenRouter AI analysis: summary, key details, potential risks, and action items
- Analysis results saved locally with each document

## Current limitations and security

- Scanned/image-only PDFs need OCR.
- Legacy `.doc` files are not supported; convert them to `.docx` or PDF.
- The assistant chat and document comparison screens are still previews.
- **Important:** Flutter dotenv loads `.env` as a bundled app asset. It prevents committing the key to Git when `.env` is ignored, but it does NOT hide the key from someone who extracts the installed APK/IPA. Before publishing, move OpenRouter requests to a secure backend and keep the key server-side.
- AI-generated risk notes are not legal, financial, or professional advice.

## Android

The app uses Android compile SDK 36. Ensure Android SDK Platform 36 is installed.


## Real document workflow

The app does not ship with sample/demo documents. Import your own files from the Library or Home screen. Imported files are copied into the app's private documents directory so their content remains available after the app is closed.

- **Analyze:** extracts text from the selected PDF, DOCX, TXT or RTF file and sends that text to the configured OpenRouter model.
- **AI Assistant:** extracts content from the files currently in your library and answers questions grounded in those documents. It identifies the source filename where possible.
- **Compare:** extracts both selected files and asks the AI to return similarities, differences, changed dates/amounts and review points.
- **Insights:** counts and format breakdowns are calculated from the actual library; no demo totals or charts are shown.

Scanned/image-only PDFs need OCR and are not currently supported by the text extractor. Legacy .doc files are not accepted; save them as .docx or PDF first. Very large documents are truncated before being sent to the model, and AI output should always be checked against the original file.

The OpenRouter key is read from .env. A bundled Flutter asset is extractable from a released app, so this setup is suitable for local development only; use a secure backend before public release.
