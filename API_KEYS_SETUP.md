# Local AI Provider Setup

The app calls AI providers directly from Flutter. Firebase Authentication and
initialization remain in place for the rest of the application; no Firebase
Cloud Function or backend is used by this AI workflow.

## Configure local keys

1. Copy `.env.example` to a new file named `.env` in the project root
   (the same folder as `pubspec.yaml`). Do not add keys to `.env.example`;
   the app loads `.env`, not the example file.
2. Replace the placeholder values in `.env` with your provider keys:

```dotenv
OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
GROQ_API_KEY=YOUR_GROQ_API_KEY
```

3. Install Flutter packages and run the app:

```bash
flutter pub get
flutter run -d chrome
```

The app tries OpenRouter `google/gemma-4-31b-it:free`, Google Gemini
`gemini-3.1-flash-lite`, then Groq `qwen/qwen3.8-27b`. Empty keys are skipped;
Groq is skipped for requests with more than three images.

## Key safety

`.env` is excluded from Git. Do not commit or share it. Any provider keys
previously pasted into chat or hardcoded in source should be revoked and
replaced before use.

These keys are bundled with a client-side Flutter app and can be extracted by
users. This local setup is for development/testing only; direct client calls
do not provide a secure way to keep provider keys secret.
