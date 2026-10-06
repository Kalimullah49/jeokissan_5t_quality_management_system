# AI Provider Integration

The existing Flutter workflow uses direct HTTP requests to the AI providers.
Image analysis/classification prompts and response parsing are in
`lib/gemini_service.dart`; the UI and Firebase Authentication flow are unchanged.

## Local setup

1. Copy `.env.example` to `.env`.
2. Set your provider keys in `.env`.
3. Run:

```bash
flutter pub get
flutter run -d chrome
```

See [API_KEYS_SETUP.md](./API_KEYS_SETUP.md) for the environment variable names
and provider key links.

## Provider order

1. OpenRouter — `openrouter/free`
2. Google Gemini — `gemini-2.5-flash`
3. Groq — `qwen/qwen3.8-27b` (supports up to three images)

Missing keys and provider/network/response errors trigger fallback to the next
configured provider. The UI receives a useful error if all configured providers
fail. The request still rejects empty, undecodable, more than four, or oversized
image sets.

## Security note

`.env` is git-ignored, but Flutter client assets are bundled into the app.
Therefore, keys included in a Flutter web or mobile build can be extracted by
users. Use this local setup for development/testing only and rotate any keys
that were previously shared or embedded in source.
