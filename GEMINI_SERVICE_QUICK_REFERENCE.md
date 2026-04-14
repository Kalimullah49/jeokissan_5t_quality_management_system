# Quick Reference: Gemini Service Multi-Level Fallback

## 🚀 Quick Start

### 1. Add Your API Keys

Edit `/lib/gemini_service.dart` lines 45-64 and replace placeholders:

```dart
static final List<ProviderTarget> _providerTargets = [
  // TARGET 1: OpenRouter
  ProviderTarget(
    apiKey: 'sk-or-v1-YOUR_ACTUAL_OPENROUTER_KEY_HERE',  // ← Replace
    // ...
  ),
  // TARGET 2: Google AI Studio
  ProviderTarget(
    apiKey: 'YOUR_ACTUAL_GOOGLE_API_KEY_HERE',  // ← Replace
    // ...
  ),
  // TARGET 3: Groq Cloud
  ProviderTarget(
    apiKey: 'YOUR_ACTUAL_GROQ_API_KEY_HERE',  // ← Replace
    // ...
  ),
];
```

### 2. How to Use in Your App

```dart
// STEP 1: Analyze image and get questions
final analysisResult = await GeminiClassificationService.analyzeAndAskQuestions(
  imageBytesList: [imageBytes1, imageBytes2],  // 1 or more images
  languageCode: 'en',  // or 'ur' for Urdu
);

print('Detected commodity: ${analysisResult['commodity']}');
print('Questions: ${analysisResult['questions']}');
print('Provider used: ${analysisResult['provider_used']}');  // 0, 1, or 2

// STEP 2: Get user answers from UI (dropdowns)
final questionsAndAnswers = [
  {'question': 'How firm is the mango?', 'answer': 'Very firm'},
  {'question': 'What is the aroma?', 'answer': 'Fresh and pleasant'},
  // ... more answers
];

// STEP 3: Classify with final quality tier
final classificationResult = await GeminiClassificationService.classifyWithAnswers(
  imageBytesList: [imageBytes1, imageBytes2],
  commodity: analysisResult['commodity'],
  questionsAndAnswers: questionsAndAnswers,
  languageCode: 'en',
);

print('Quality Tier: ${classificationResult['tier']}');  // Excellent, Very Good, Good, Satisfactory, Unsatisfactory
print('Confidence: ${classificationResult['confidence']}');  // 0.0 - 1.0
print('Reasons: ${classificationResult['reasons']}');
print('Provider used: ${classificationResult['provider_used']}');
```

---

## 🔄 Fallback Flow Diagram

```
User uploads image(s)
        ↓
┌─────────────────────────────────────┐
│ Try Provider 0: OpenRouter          │
│ - Model: Gemini 2.0 Flash           │
│ - Format: OpenAI (messages)         │
└─────────────────────────────────────┘
        ↓
    Status?
    ↙  ↓  ↘
  200  4xx  5xx
  ✅   ❌   ⚠️
  │    │    │
  │    │    └─→ Fallback to Provider 1
  │    │
  │    └──→ FATAL ERROR (throw exception)
  │         No fallback!
  │
  └──→ SUCCESS (return result)
       Done! 🎉
       
If Provider 1 also fails on 5xx:
        ↓
┌─────────────────────────────────────┐
│ Try Provider 1: Google AI Studio    │
│ - Model: Gemini 2.0 Flash           │
│ - Format: Gemini (contents)         │
└─────────────────────────────────────┘
        ↓
    Status?
    ↙  ↓  ↘
  200  4xx  5xx
  ✅   ❌   ⚠️
  │    │    │
  │    │    └─→ Fallback to Provider 2
  │    │
  │    └──→ FATAL ERROR (throw exception)
  │
  └──→ SUCCESS (return result)

If Provider 2 also fails:
        ↓
┌─────────────────────────────────────┐
│ Try Provider 2: Groq Cloud          │
│ - Model: Llama 3.2 90B Vision       │
│ - Format: OpenAI (messages)         │
└─────────────────────────────────────┘
        ↓
    Status?
    ↙  ↓  ↘
  200  4xx  5xx
  ✅   ❌   ⚠️
  │    │    │
  │    │    │
  │    │    └─→ All providers failed!
  │    │
  │    └──→ FATAL ERROR (throw exception)
  │
  └──→ SUCCESS (return result)

If all 3 providers fail:
        ↓
        ❌ Exception thrown:
        "All AI providers are currently unavailable.
         Last error: Provider 3 (Groq Cloud) failed with status 503"
```

---

## 📊 HTTP Status Code Reference

| Code | Category | Action |
|------|----------|--------|
| **200** | ✅ Success | Use response, stop loop |
| **400** | ❌ Fatal | Throw exception, no fallback |
| **401** | ❌ Fatal | Throw exception, no fallback |
| **403** | ❌ Fatal | Throw exception, no fallback |
| **404** | ❌ Fatal | Throw exception, no fallback |
| **429** | ⚠️ Fallback | Try next provider |
| **500** | ⚠️ Fallback | Try next provider |
| **502** | ⚠️ Fallback | Try next provider |
| **503** | ⚠️ Fallback | Try next provider |
| **504** | ⚠️ Fallback | Try next provider |
| **Other** | ⚠️ Fallback | Try next provider |

---

## 🐛 Debug Logging

The service logs all fallback attempts using `debugPrint()`.

### Enable Debug Logs in Console:

```
flutter run --verbose
```

### Sample Debug Output:

```
🔄 Attempting Provider 0: OpenRouter (Gemini 2.0 Flash)
📊 Provider 0 response status: 503
⚠️  Provider 0 failed with fallback status (503), trying next...

🔄 Attempting Provider 1: Google AI Studio (Gemini 2.0 Flash)
📊 Provider 1 response status: 200
✅ Provider 1 succeeded

[Result returned from Provider 1]
```

### Check Which Provider Succeeded:

```dart
final result = await GeminiClassificationService.analyzeAndAskQuestions(...);

if (result['provider_used'] == 0) {
  print('Used OpenRouter');
} else if (result['provider_used'] == 1) {
  print('Used Google AI Studio');
} else if (result['provider_used'] == 2) {
  print('Used Groq Cloud');
}
```

---

## ✅ Testing Checklist

### Test 1: Primary Provider Success
- [ ] Add valid OpenRouter API key
- [ ] Upload agricultural commodity image
- [ ] Verify debug log shows: `✅ Provider 0 succeeded`
- [ ] Verify result contains questions and classifications
- [ ] Verify `provider_used == 0`

### Test 2: Fallback to Secondary Provider
- [ ] Disable/invalidate OpenRouter API key (or simulate 503)
- [ ] Upload image again
- [ ] Verify debug log shows: `⚠️ Provider 0 failed...`
- [ ] Verify debug log shows: `✅ Provider 1 succeeded`
- [ ] Verify `provider_used == 1`

### Test 3: Fallback to Tertiary Provider
- [ ] Disable first two providers
- [ ] Upload image again
- [ ] Verify both fall back and Provider 2 (Groq) succeeds
- [ ] Verify `provider_used == 2`

### Test 4: All Providers Fail
- [ ] Disable all three API keys
- [ ] Upload image again
- [ ] Verify exception is thrown:
  ```
  Exception: All AI providers are currently unavailable.
  Last error: ...
  ```

### Test 5: Non-Agricultural Image Rejection
- [ ] Upload image of person, car, or building
- [ ] Verify immediate rejection (no fallback)
- [ ] Verify error message matches language code (English/Urdu)

### Test 6: Fatal Client Error (no fallback)
- [ ] Use invalid API key format
- [ ] Trigger 400 or 401 response
- [ ] Verify exception is thrown immediately
- [ ] Verify NO fallback occurs (no Provider 1 attempt)

### Test 7: Multiple Images
- [ ] Upload 2-3 images of same commodity
- [ ] Verify all images are compressed and sent
- [ ] Verify AI analyzes all images for questions
- [ ] Verify final classification uses all images

### Test 8: Bilingual Support
- [ ] Test with `languageCode: 'en'` (English)
- [ ] Verify questions and classifications are in English
- [ ] Test with `languageCode: 'ur'` (Urdu)
- [ ] Verify questions and classifications are in Urdu

---

## 🔧 Provider-Specific Details

### OpenRouter (Target 1)
```dart
Endpoint:  https://openrouter.ai/api/v1/chat/completions
Model:     google/gemini-2.0-flash-001
Format:    OpenAI-compatible
Auth:      Bearer token in Authorization header
Header:    'Authorization': 'Bearer YOUR_KEY'
```

### Google AI Studio (Target 2)
```dart
Endpoint:  https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
Model:     gemini-2.0-flash
Format:    Gemini REST (contents array)
Auth:      API key as query parameter
Header:    'Content-Type': 'application/json'
```

### Groq Cloud (Target 3)
```dart
Endpoint:  https://api.groq.com/openai/v1/chat/completions
Model:     llama-3.2-90b-vision-preview
Format:    OpenAI-compatible
Auth:      Bearer token in Authorization header
Header:    'Authorization': 'Bearer YOUR_KEY'
```

---

## 🎯 Performance Tips

1. **Image Compression:** Images are automatically compressed to max 800px width at 70% quality
   - Typical size reduction: ~70% smaller
   - Typical API response time: 3-8 seconds

2. **Request Timeout:** 60 seconds per provider
   - If slower, automatically tries next provider

3. **Multi-image Handling:** All images are processed together
   - Send 2-3 angles for better analysis accuracy

4. **Language Setting:**
   - English: Faster (native for all providers)
   - Urdu: Same speed (models handle both)

---

## ⚠️ Common Issues

### Issue: "Fatal error (401)"
**Cause:** Invalid API key
**Solution:** Verify API key is correct and active

### Issue: "All providers unavailable"
**Cause:** All three providers failed
**Solution:** Check internet connection, API key validity, rate limits

### Issue: "Status: 429"
**Cause:** Rate limit exceeded on provider
**Solution:** Wait and retry, or use provider with higher limits

### Issue: Non-agricultural image accepted
**Cause:** AI didn't detect non-farm image properly
**Solution:** This is rare; AI is designed to reject non-agricultural content

### Issue: Wrong language in response
**Cause:** `languageCode` parameter not set correctly
**Solution:** Use `'en'` or `'ur'`, not other values

---

## 📞 Support

For API key issues, visit:
- **OpenRouter:** https://openrouter.ai
- **Google AI Studio:** https://aistudio.google.com
- **Groq Cloud:** https://console.groq.com

---

## 📝 File Reference

**Main Implementation:** `/lib/gemini_service.dart`
**Documentation:** `/GEMINI_SERVICE_FALLBACK_IMPLEMENTATION.md`
**Total Lines:** 573 (well-structured, documented)

Happy coding! 🚀
