import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class GeminiClassificationService {
  // ── OpenRouter API Key ───────────────────────────────────────────────
  static const String _apiKey =
      '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';

  // ── OpenRouter endpoint ──────────────────────────────────────────────
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // ── Model ────────────────────────────────────────────────────────────
  static const String _model = 'google/gemini-2.0-flash-001';

  // ── Helper: compress image to reduce payload size ────────────────────
  static Uint8List _compressImage(Uint8List bytes, {int maxWidth = 800, int quality = 70}) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      // Only resize if larger than maxWidth
      img.Image resized;
      if (decoded.width > maxWidth || decoded.height > maxWidth) {
        resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? maxWidth : null,
          height: decoded.height >= decoded.width ? maxWidth : null,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = decoded;
      }

      // Encode as JPEG with quality setting
      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (_) {
      // If compression fails, return original
      return bytes;
    }
  }

  // ── Helper: call OpenRouter API ──────────────────────────────────────
  static Future<String> _callOpenRouter(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://jeokissan-quality-manual.web.app',
        'X-Title': 'JeoKissan QMS',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error (${response.statusCode}): ${response.body}');
    }

    final responseData = json.decode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from OpenRouter: ${response.body}');
    }

    final message = choices[0]['message'] as Map<String, dynamic>;
    return message['content'] as String? ?? '';
  }

  // ── Helper: parse JSON from text ─────────────────────────────────────
  static Map<String, dynamic> _parseJson(String text) {
    try {
      return json.decode(text) as Map<String, dynamic>;
    } catch (_) {
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace > firstBrace) {
        final jsonStr = text.substring(firstBrace, lastBrace + 1);
        return json.decode(jsonStr) as Map<String, dynamic>;
      }
      throw Exception('Failed to parse response: $text');
    }
  }

  // ====================================================================
  // STEP 1: Analyze image(s) → generate follow-up questions
  // ====================================================================
  static Future<Map<String, dynamic>> analyzeAndAskQuestions({
    required List<Uint8List> imageBytesList,
    List<String>? fileNames,
    String languageCode = 'en', // 'en' or 'ur' for Urdu
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Please set your OpenRouter API key');
    }

    // Build image content parts
    final List<Map<String, dynamic>> contentParts = [
      {
        'type': 'text',
        'text': 'Analyze ${imageBytesList.length > 1 ? "these ${imageBytesList.length} images of the same commodity" : "this commodity image"} and generate follow-up questions to help determine its quality tier accurately. Return ONLY valid JSON.',
      },
    ];

    for (int i = 0; i < imageBytesList.length; i++) {
      // Compress image to reduce payload size and speed up API call
      final compressed = _compressImage(imageBytesList[i]);
      final base64Image = base64Encode(compressed);
      contentParts.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$base64Image',
        },
      });
    }

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': '''You are an expert post-harvest quality analyst for agricultural commodities.

RESPONSE LANGUAGE: ${languageCode == 'ur' ? 'Urdu (اردو)' : 'English'}

CRITICAL RULE: You MUST ONLY process images of AGRICULTURAL COMMODITIES such as:
- Fruits (mango, apple, banana, grapes, citrus, etc.)
- Vegetables (tomato, potato, onion, carrot, spinach, etc.)
- Grains & Cereals (wheat, rice, maize, barley, etc.)
- Pulses & Legumes (lentils, chickpeas, beans, etc.)
- Spices (turmeric, chili, cumin, coriander, etc.)
- Nuts & Dry Fruits (almonds, cashews, raisins, dates, etc.)
- Oilseeds (mustard, sunflower, soybean, etc.)
- Other farm produce (sugarcane, cotton, jute, tea leaves, etc.)

If the image does NOT contain an agricultural commodity (e.g., it shows a person, animal, vehicle, building, electronics, clothing, or any non-agricultural item), you MUST respond with ONLY this JSON:
{"error": "NOT_AGRICULTURAL", "message": "${languageCode == 'ur' ? 'یہ تصویر زرعی اجناس پر مشتمل نہیں ہے۔ براہ کرم پھل، سبزی، اناج، دال، مصالحے، یا دیگر زرعی پیداوار کی تصویر اپ لوڈ کریں۔' : 'This image does not contain an agricultural commodity. Please upload an image of a fruit, vegetable, grain, pulse, spice, or other farm produce.'}"}

Do NOT process, analyze, or classify any non-agricultural image under any circumstances.

If the image IS an agricultural commodity, look at ${imageBytesList.length > 1 ? "ALL the images" : "the image"} carefully and:
1. Identify what commodity it is
2. Do a preliminary visual assessment based on ${imageBytesList.length > 1 ? "all images combined" : "the image"}
3. Generate 4-5 follow-up questions STRICTLY about the PHYSICAL ATTRIBUTES of the commodity that you cannot fully determine from the ${imageBytesList.length > 1 ? "images" : "image"} alone

The questions MUST ONLY be about physical/sensory characteristics such as:
- Firmness or softness when touched/pressed
- Smell or aroma (fresh, sour, fermented, no smell, etc.)
- Weight or heaviness compared to normal
- Texture of the skin/surface (smooth, rough, sticky, dry, slimy)
- Internal colour or flesh condition (if cut open)
- Presence of any hidden spots, holes, or damage underneath
- Juiciness or moisture level
- Seed/pit condition
- Any unusual taste (if tasted)
- Physical size compared to standard for this commodity

DO NOT ask about storage, transport, harvest date, chemical treatment, origin, intended use, or any non-physical attributes.

Output ONLY a valid JSON object — no markdown, no code fences (in ${languageCode == 'ur' ? 'Urdu' : 'English'}):
{
  "commodity": "<detected commodity name>",
  "preliminary_assessment": "<1-2 sentence visual assessment>",
  "questions": [
    {"id": 1, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 2, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 3, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]},
    {"id": 4, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 5, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]}
  ]
}

IMPORTANT: Every question MUST have "type": "dropdown" and an "options" array with 3-5 relevant answer choices. Make options specific and descriptive for the commodity. ${languageCode == 'ur' ? 'تمام سوالات اور جوابات اردو میں ہوں۔' : 'All questions and answers must be in the specified language.'}''',
        },
        {
          'role': 'user',
          'content': contentParts,
        },
      ],
      'max_tokens': 700,
      'temperature': 0.2,
    };

    final text = await _callOpenRouter(body);
    final parsed = _parseJson(text);

    // Check if AI rejected the image as non-agricultural
    if (parsed.containsKey('error') && parsed['error'] == 'NOT_AGRICULTURAL') {
      throw Exception(parsed['message'] ?? 'This is not an agricultural commodity image. Please upload a fruit, vegetable, grain, or other farm produce.');
    }

    if (!parsed.containsKey('questions')) {
      throw Exception('Missing "questions" in response');
    }
    return parsed;
  }

  // ====================================================================
  // STEP 2: Final classification using image(s) + user answers
  // ====================================================================
  static Future<Map<String, dynamic>> classifyWithAnswers({
    required List<Uint8List> imageBytesList,
    List<String>? fileNames,
    required String commodity,
    required List<Map<String, String>> questionsAndAnswers,
    String languageCode = 'en', // 'en' or 'ur' for Urdu
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Please set your OpenRouter API key');
    }

    // Format Q&A for the prompt
    final qaText = questionsAndAnswers
        .map((qa) => 'Q: ${qa["question"]}\nA: ${qa["answer"]}')
        .join('\n\n');

    // Build image content parts
    final List<Map<String, dynamic>> contentParts = [
      {
        'type': 'text',
        'text': 'Here ${imageBytesList.length > 1 ? "are ${imageBytesList.length} images of the same" : "is the"} commodity and the user\'s answers to the follow-up questions.\n\nCommodity: $commodity\n\n$qaText\n\nNow give the FINAL 5-tier quality classification based on ${imageBytesList.length > 1 ? "all images" : "the image"} and these answers. Return ONLY valid JSON.',
      },
    ];

    for (int i = 0; i < imageBytesList.length; i++) {
      // Compress image to reduce payload size and speed up API call
      final compressed = _compressImage(imageBytesList[i]);
      final base64Image = base64Encode(compressed);
      contentParts.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$base64Image',
        },
      });
    }

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': '''You are an expert post-harvest quality analyst for agricultural commodities.

RESPONSE LANGUAGE: ${languageCode == 'ur' ? 'Urdu (اردو)' : 'English'}

CRITICAL RULE: You MUST ONLY process images of AGRICULTURAL COMMODITIES (fruits, vegetables, grains, pulses, spices, nuts, dry fruits, oilseeds, or other farm produce). If the image does NOT contain an agricultural commodity, respond with ONLY this JSON:
{"error": "NOT_AGRICULTURAL", "message": "${languageCode == 'ur' ? 'یہ تصویر زرعی اجناس پر مشتمل نہیں ہے۔ براہ کرم پھل، سبزی، اناج، دال، مصالحے، یا دیگر زرعی پیداوار کی تصویر اپ لوڈ کریں۔' : 'This image does not contain an agricultural commodity. Please upload an image of a fruit, vegetable, grain, pulse, spice, or other farm produce.'}"}

You have already analyzed the image(s) visually. Now you also have the user's answers to your follow-up questions. Use BOTH the image(s) AND the answers to make your FINAL quality classification.

Classify into EXACTLY ONE of these five tiers:

${languageCode == 'ur' ? '''1. **بہترین (Excellent)** – پریمیم برآمدی درجہ۔ یکساں سائز/شکل، روشن قدرتی رنگ، کوئی داغ نہیں، کوئی کیڑے نہیں، مضبوط ساخت، تازہ خوشبو۔
2. **بہت اچھا (Very Good)** – اعلیٰ گھریلو منڈی کا درجہ۔ صرف معمولی خوبصورتی کی خامیاں (تھوڑا رنگ کی تبدیلی، ریت کے نشانات ≤5%)۔ کوئی سڑن یا کیڑے کے سبوت نہیں۔
3. **اچھا (Good)** – معیاری منڈی قابل قبول درجہ۔ اعتدال پسند خوبصورتی کے مسائل (رنگ کی بے قاعدگی، چھوٹے چھلنے، معمولی کمزوری، معمولی شکل کی بے ترتیبی)۔ ابھی محفوظ اور غذائی۔
4. **مناسب (Satisfactory)** – اوسط سے نیچے کا درجہ، صرف پروسیسنگ/قدر اضافی کے لیے قابل قبول۔ نمایاں خامیاں: جزوی بے رنگی، نرم دھبے، ابتدائی مرحلہ سکڑنا، معمولی کیڑے کے نشانات۔
5. **ناقص (Unsatisfactory)** – مسترد / غیر فروخت شدہ۔ اہم سڑن، سفیدی، بھاری کیڑے، بدبو، ڈھانچے کا انہدام، یا غیر ملکی معاملات۔''' : '''1. **Excellent** – Premium export-grade. Uniform size/shape, vibrant natural colour, zero blemishes, no pest damage, firm texture, fresh aroma expected.
2. **Very Good** – High domestic-market grade. Minor cosmetic imperfections only (slight colour variation, tiny surface marks ≤5% area). No decay or pest evidence.
3. **Good** – Standard market-acceptable grade. Moderate cosmetic issues (colour unevenness, small bruises, slight wilting, minor shape irregularity). Still safe and nutritious.
4. **Satisfactory** – Below-average grade, acceptable for processing/value-addition only. Noticeable defects: partial discolouration, soft spots, early-stage shrivelling, minor insect traces.
5. **Unsatisfactory** – Rejected / unmarketable. Significant rot, mould, heavy pest infestation, foul odour indicators, structural collapse, or foreign-matter contamination.'''}

RULES:
• Use BOTH the visual evidence AND the user's answers for your assessment.
• When uncertain between two adjacent tiers, pick the LOWER tier.
• Output ONLY a valid JSON object — no markdown, no code fences.
• ${languageCode == 'ur' ? 'تمام جوابات، وجوہات اور اقدامات اردو میں ہوں۔' : 'All responses must be in the specified language.'}

Required JSON schema (${languageCode == 'ur' ? 'Urdu' : 'English'}):
{
  "tier": "<${languageCode == 'ur' ? 'بہترین | بہت اچھا | اچھا | مناسب | ناقص' : 'Excellent | Very Good | Good | Satisfactory | Unsatisfactory'}>",
  "confidence": <float 0.0–1.0>,
  "commodity": "<commodity name>",
  "reasons": ["<reason 1>", "<reason 2>", ...],
  "corrective_actions": ["<action 1>", ...],
  "notes": "<optional string, max 200 chars, or empty string>"
}''',
        },
        {
          'role': 'user',
          'content': contentParts,
        },
      ],
      'max_tokens': 512,
      'temperature': 0.1,
    };

    final text = await _callOpenRouter(body);
    final parsed = _parseJson(text);

    // Check if AI rejected the image as non-agricultural
    if (parsed.containsKey('error') && parsed['error'] == 'NOT_AGRICULTURAL') {
      throw Exception(parsed['message'] ?? 'This is not an agricultural commodity image.');
    }

    if (!parsed.containsKey('tier')) {
      throw Exception('Missing "tier" in response');
    }
    return parsed;
  }
}
