# Quick Deployment Checklist

## ✅ What Has Been Done

### Backend (Python Cloud Functions)
- [x] `functions/main.py` created with 2 HTTPS Callable functions
  - `analyze_and_ask_questions()` - Step 1 analysis
  - `classify_with_answers()` - Step 2 classification
- [x] Auth enforcement - functions verify `req.auth` before processing
- [x] Secret Manager integration - fetches `OPENROUTER_KEY_1` securely
- [x] Full error handling - unauthenticated, invalid-argument, NOT_AGRICULTURAL
- [x] `functions/requirements.txt` - all dependencies listed

### Frontend (Flutter/Dart)
- [x] `pubspec.yaml` - replaced `http` with `cloud_functions: ^4.7.0`
- [x] `lib/gemini_service.dart` - complete refactor
  - Removed hardcoded API key
  - Removed direct http calls to OpenRouter
  - Kept local image compression (bandwidth optimization)
  - Added cloud function calls via `FirebaseFunctions.instance.httpsCallable()`
  - Comprehensive exception handling for all error scenarios

### Documentation
- [x] `CLOUD_FUNCTIONS_MIGRATION.md` - complete setup guide
- [x] Architecture diagrams and data flow
- [x] Troubleshooting section
- [x] Cost analysis
- [x] Production checklist

---

## 🚀 What You Need To Do Next

### Phase 1: Immediate (Before Testing)

```bash
# 1. Update Flutter dependencies
cd /Users/kalimullah/Jeokissan/jeokissan_5t_quality_management_system
flutter pub get

# 2. Verify no compilation errors
flutter analyze
```

**Time:** ~2-3 minutes

### Phase 2: Set Up Secret Manager (Critical)

1. Go to **Google Cloud Console**
   - Project: `jeokissan-quality-manual`
   - Navigate to **Secret Manager** (under Security → Secret Manager)

2. Click **Create Secret**
   - Name: `OPENROUTER_KEY_1`
   - Value: `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`
   - Click **Create Secret**

3. Grant Firebase Functions Access
   - Select the secret `OPENROUTER_KEY_1`
   - Go to **Permissions** tab
   - Click **Grant Access**
   - Principal: `<PROJECT_NUMBER>@cloudservices.gserviceaccount.com`
     (Find PROJECT_NUMBER in Project Settings)
   - Role: **Secret Accessor**
   - Click **Save**

**Time:** ~5 minutes

### Phase 3: Deploy Cloud Functions

```bash
# 1. Ensure you're logged into Firebase CLI
firebase login

# 2. Select your project
firebase use jeokissan-quality-manual

# 3. Deploy functions
firebase deploy --only functions

# Expected output:
# Functions deploy complete!
# Functions in project: jeokissan-quality-manual:
#   • analyze_and_ask_questions
#   • classify_with_answers
```

**Time:** ~3-5 minutes

### Phase 4: Verify Deployment

1. **Firebase Console:**
   - Go to **Build** → **Functions**
   - Verify both functions appear and show "Running" status

2. **Check Logs:**
   ```bash
   firebase functions:log --limit 10
   ```

**Time:** ~1 minute

### Phase 5: Test with Flutter

```bash
# Test on emulator or device
flutter run

# Test the workflow:
# 1. Log in with your Firebase account
# 2. Upload an image
# 3. Answer questions
# 4. View classification
```

**Time:** ~5 minutes

---

## 📋 Function Signatures

### analyze_and_ask_questions

**Request:**
```dart
{
  "base64_images": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",  // Multiple supported
    "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  ],
  "language_code": "en"  // "en" or "ur"
}
```

**Response:**
```json
{
  "commodity": "Mango",
  "preliminary_assessment": "Visual inspection suggests Sindhri variety...",
  "questions": [
    {
      "id": 1,
      "question": "How firm is the mango when gently pressed?",
      "type": "dropdown",
      "options": ["Very firm", "Slightly soft", "Very soft"]
    }
  ]
}
```

### classify_with_answers

**Request:**
```dart
{
  "base64_images": ["data:image/jpeg;base64,..."],
  "commodity": "Mango",
  "questions_and_answers": [
    {
      "question": "How firm is the mango?",
      "answer": "Slightly soft"
    }
  ],
  "language_code": "en"
}
```

**Response:**
```json
{
  "tier": "Very Good",
  "confidence": 0.92,
  "commodity": "Mango",
  "reasons": [
    "Uniform size and shape",
    "Vibrant natural color with no blemishes"
  ],
  "corrective_actions": [],
  "notes": "Ready for export market"
}
```

---

## 🔒 Security Verification

After deployment, verify the hardcoded API key is removed:

```bash
# Confirm no API keys in source code
grep -r "sk-or-v1" lib/

# Should return: (empty)

# Confirm Cloud Function has the key
grep -r "OPENROUTER_KEY_1" functions/

# Should return: functions/main.py (multiple matches in Secret Manager code)
```

---

## 🆘 If Something Goes Wrong

### Functions not appearing in console?
```bash
firebase deploy --only functions --debug
# Check output for errors related to main.py syntax
```

### Secret Manager permission denied?
```bash
# Check IAM bindings
gcloud functions describe analyze_and_ask_questions --gen2 --region=us-central1
# Ensure service account has secretmanager.secretAccessor role
```

### Flutter app can't connect to functions?
```bash
# Verify Firebase is initialized in main.dart
# Confirm user is logged in (check Firebase Console → Authentication)
# Check functions logs:
firebase functions:log --tail
```

---

## 📞 Support References

- **Firebase Cloud Functions Docs:** https://firebase.google.com/docs/functions
- **Secret Manager Docs:** https://cloud.google.com/secret-manager/docs
- **OpenRouter API Docs:** https://openrouter.ai/api/v1/completions
- **Flutter Cloud Functions:** https://pub.dev/packages/cloud_functions

---

## ⏱️ Total Estimated Time: ~20 minutes

| Phase | Time | Status |
|-------|------|--------|
| Phase 1: Flutter dependencies | 2-3 min | ⬜ TODO |
| Phase 2: Secret Manager setup | 5 min | ⬜ TODO |
| Phase 3: Deploy functions | 3-5 min | ⬜ TODO |
| Phase 4: Verify deployment | 1 min | ⬜ TODO |
| Phase 5: Test with Flutter | 5 min | ⬜ TODO |

**Once complete, your app is fully secure with zero hardcoded API keys! 🎉**
