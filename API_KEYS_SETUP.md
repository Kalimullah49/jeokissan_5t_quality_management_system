# API Key Replacement Guide

## Quick Setup Instructions

### Step 1: Get Your API Keys

#### OpenRouter (Target 1)
1. Go to https://openrouter.ai
2. Sign up / Log in
3. Navigate to API Keys section
4. Copy your API key (starts with `sk-or-v1-`)

#### Google AI Studio (Target 2)
1. Go to https://aistudio.google.com
2. Sign in with Google account
3. Click "Get API key"
4. Create new API key
5. Copy the key

#### Groq Cloud (Target 3)
1. Go to https://console.groq.com
2. Sign up / Log in
3. Navigate to API Keys
4. Create new API key
5. Copy the key

---

## Step 2: Update gemini_service.dart

### Location
File: `/lib/gemini_service.dart`, Lines 45-64

### Current Code (with placeholders)
```dart
static final List<ProviderTarget> _providerTargets = [
  // TARGET 1: OpenRouter (Gemini 2.0 Flash)
  ProviderTarget(
    type: ProviderType.openRouter,
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    model: 'google/gemini-2.0-flash-001',
    apiKey: 'sk-or-v1-YOUR_OPENROUTER_API_KEY_HERE', // ← REPLACE THIS
    description: 'OpenRouter (Gemini 2.0 Flash)',
  ),
  // TARGET 2: Google AI Studio (Gemini 2.0 Flash via REST)
  ProviderTarget(
    type: ProviderType.googleAI,
    endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    model: 'gemini-2.0-flash',
    apiKey: 'YOUR_GOOGLE_API_KEY_HERE', // ← REPLACE THIS
    description: 'Google AI Studio (Gemini 2.0 Flash)',
  ),
  // TARGET 3: Groq Cloud (Llama 3.2 90B Vision)
  ProviderTarget(
    type: ProviderType.groq,
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.2-90b-vision-preview',
    apiKey: 'YOUR_GROQ_API_KEY_HERE', // ← REPLACE THIS
    description: 'Groq Cloud (Llama 3.2 90B Vision)',
  ),
];
```

### Example After Replacement
```dart
static final List<ProviderTarget> _providerTargets = [
  // TARGET 1: OpenRouter (Gemini 2.0 Flash)
  ProviderTarget(
    type: ProviderType.openRouter,
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    model: 'google/gemini-2.0-flash-001',
    apiKey: 'sk-or-v1-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t', // ✅ Real key
    description: 'OpenRouter (Gemini 2.0 Flash)',
  ),
  // TARGET 2: Google AI Studio (Gemini 2.0 Flash via REST)
  ProviderTarget(
    type: ProviderType.googleAI,
    endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    model: 'gemini-2.0-flash',
    apiKey: 'AIzaSyDx1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z', // ✅ Real key
    description: 'Google AI Studio (Gemini 2.0 Flash)',
  ),
  // TARGET 3: Groq Cloud (Llama 3.2 90B Vision)
  ProviderTarget(
    type: ProviderType.groq,
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.2-90b-vision-preview',
    apiKey: 'gsk_abcd1234efgh5678ijkl90mnopqrstu', // ✅ Real key
    description: 'Groq Cloud (Llama 3.2 90B Vision)',
  ),
];
```

---

## Step 3: Verify in VS Code

### Find & Replace Approach (Quick)

1. **Open the file:** `lib/gemini_service.dart`
2. **Press:** `Ctrl+H` (or `Cmd+H` on Mac)
3. **Find:** `'sk-or-v1-YOUR_OPENROUTER_API_KEY_HERE'`
4. **Replace with:** `'sk-or-v1-[your-actual-key]'`
5. **Click Replace** (not Replace All - do one at a time for each provider)
6. **Repeat for the other 2 API keys**

### Manual Approach

1. Open `lib/gemini_service.dart`
2. Go to line 52 (OpenRouter key)
3. Replace the placeholder with your real key
4. Go to line 61 (Google AI key)
5. Replace the placeholder with your real key
6. Go to line 68 (Groq key)
7. Replace the placeholder with your real key
8. Save the file

---

## Step 4: Test the Implementation

### Simple Test in Flutter
```dart
// In any widget method or test
try {
  final result = await GeminiClassificationService.analyzeAndAskQuestions(
    imageBytesList: [yourImageBytes],
    languageCode: 'en',
  );
  print('Success! Provider used: ${result['provider_used']}');
  print('Commodity: ${result['commodity']}');
} catch (e) {
  print('Error: $e');
}
```

### Check Debug Logs
1. Run: `flutter run -d chrome`
2. Look for these messages in console:
   - `🔄 Attempting Provider 0: OpenRouter...` → First attempt
   - `✅ Provider 0 succeeded` → API key is valid ✅
   - `❌ Provider 0 returned fatal client error (401)` → Invalid key ❌

---

## Troubleshooting

### Error: "Fatal error from OpenRouter (401)"
**Cause:** Invalid API key
**Solution:** 
1. Check if you copied the full key (no spaces before/after)
2. Verify the key is active in your OpenRouter account
3. Make sure the key starts with `sk-or-v1-`

### Error: "All AI providers are currently unavailable"
**Cause:** All three API keys are invalid or providers are down
**Solution:**
1. Test each API individually at their websites
2. Check if you have API credits/quota remaining
3. Verify internet connection

### Error: "Fatal error from Google AI (403)"
**Cause:** API key not authorized for this model
**Solution:**
1. Enable Gemini 2.0 Flash in your Google Cloud project
2. Wait 5 minutes for changes to propagate
3. Try a different Google project

### Error: "Fatal error from Groq (429)"
**Cause:** Rate limit exceeded
**Solution:**
1. Wait a few minutes before retrying
2. Check if you have remaining quota
3. Groq has generous free tier - may need to check usage

---

## Verification Checklist

After adding API keys, verify:

- [ ] All 3 placeholder strings replaced with real keys
- [ ] No spaces before/after keys
- [ ] Keys match the format for each provider
- [ ] File saved successfully
- [ ] No syntax errors (run `flutter analyze lib/gemini_service.dart`)
- [ ] Hot reload doesn't cause compile errors
- [ ] Debug logs show "Provider X succeeded"

---

## Key Format Reference

### OpenRouter
- **Format:** `sk-or-v1-[40-character alphanumeric string]`
- **Example:** `sk-or-v1-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t`
- **Starts with:** `sk-or-v1-`

### Google AI Studio
- **Format:** `AIzaSy[40-character alphanumeric string]`
- **Example:** `AIzaSyDx1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z`
- **Starts with:** `AIzaSy`

### Groq Cloud
- **Format:** `gsk_[alphanumeric string]`
- **Example:** `gsk_abcd1234efgh5678ijkl90mnopqrstu`
- **Starts with:** `gsk_`

---

## Security Best Practices

⚠️ **Important:** API keys should NOT be committed to Git!

### Recommended for Production:
1. Use environment variables
2. Load from `.env` file (add to `.gitignore`)
3. Use Firebase Cloud Functions to proxy API calls
4. Use Portkey AI Gateway for secure key management

### For Development Only:
- Hardcoded keys are acceptable (your current setup)
- Just don't push them to public repositories
- Consider adding `lib/gemini_service.dart` to `.gitignore` if committing real keys

---

## Example .env File (Optional)

Create `.env` file in project root:
```
OPENROUTER_API_KEY=sk-or-v1-your-key-here
GOOGLE_API_KEY=AIzaSy-your-key-here
GROQ_API_KEY=gsk_-your-key-here
```

Then load in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiKey = dotenv.env['OPENROUTER_API_KEY']!;
```

(You'd need to add `flutter_dotenv` package)

---

## Support

If API keys aren't working:

1. **OpenRouter Support:** https://openrouter.ai/docs
2. **Google API Docs:** https://ai.google.dev/docs
3. **Groq Docs:** https://console.groq.com/docs

---

**Ready to go!** 🚀  
After adding your API keys, the fallback system is ready to use.
