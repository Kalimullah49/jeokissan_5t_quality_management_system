import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:jeokissan_5t_quality_management_system/commodity_name_mapping.dart';

// ════════════════════════════════════════════════════════════════════════════
// PROVIDER TYPE ENUMERATION
// ════════════════════════════════════════════════════════════════════════════

/// Provider type identification for fallback mechanism
enum ProviderType { openRouter, googleAI, groq }

// ════════════════════════════════════════════════════════════════════════════
// PROVIDER TARGET CONFIGURATION
// ════════════════════════════════════════════════════════════════════════════

/// Represents a single API provider target with endpoint, model, and authentication
class ProviderTarget {
  final ProviderType type;
  final String endpoint;
  final String model;
  final String apiKey;
  final String description;

  const ProviderTarget({
    required this.type,
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.description,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN CLASSIFICATION SERVICE
// ════════════════════════════════════════════════════════════════════════════

class GeminiClassificationService {
  // ────────────────────────────────────────────────────────────────────────────
  // MULTI-LEVEL FALLBACK PROVIDER CONFIGURATION
  // ────────────────────────────────────────────────────────────────────────────

  /// Fallback targets in priority order (Target 1 → Target 2 → Target 3)
  static final List<ProviderTarget> _providerTargets = [
    // TARGET 1: OpenRouter (Gemini 2.0 Flash)
    ProviderTarget(
      type: ProviderType.openRouter,
      endpoint: 'https://openrouter.ai/api/v1/chat/completions',
      model: 'google/gemini-2.0-flash-001',
      apiKey: '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', // PLACEHOLDER: Replace with actual key
      description: 'OpenRouter (Gemini 2.0 Flash)',
    ),
    // TARGET 2: Google AI Studio (Gemini 2.0 Flash via REST)
    ProviderTarget(
      type: ProviderType.googleAI,
      endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      model: 'gemini-2.0-flash',
      apiKey: 'AIzaSyCxfi1vczNp5hIo4rE40f5aESEciUQxFHQ', // PLACEHOLDER: Replace with actual key
      description: 'Google AI Studio (Gemini 2.0 Flash)',
    ),
    // TARGET 3: Groq Cloud (Llama 3.2 90B Vision)
    ProviderTarget(
      type: ProviderType.groq,
      endpoint: 'https://api.groq.com/openai/v1/chat/completions',
      model: 'llama-3.2-90b-vision-preview',
      apiKey: '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', // PLACEHOLDER: Replace with actual key
      description: 'Groq Cloud (Llama 3.2 90B Vision)',
    ),
  ];

  /// Status codes that trigger fallback behavior (transient server errors)
  static const List<int> _fallbackStatusCodes = [429, 500, 502, 503, 504];

  /// Status codes that cause immediate failure without fallback (fatal client errors)
  static const List<int> _fatalClientErrorCodes = [400, 401, 403, 404];

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: IMAGE COMPRESSION
  // ────────────────────────────────────────────────────────────────────────────

  /// Compress image to reduce payload size and improve API call speed
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
      // If compression fails, return original bytes
      return bytes;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: JSON PARSING
  // ────────────────────────────────────────────────────────────────────────────

  /// Parse JSON from text, extracting valid JSON if wrapped in other content
  static Map<String, dynamic> _parseJson(String text) {
    try {
      print('📝 Parsing response text (length: ${text.length})');
      final result = json.decode(text) as Map<String, dynamic>;
      print('✅ JSON parsed successfully');
      return result;
    } catch (e) {
      print('⚠️ Initial JSON parse failed: $e');
      // Try to extract JSON from markdown code blocks or mixed content
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace > firstBrace) {
        final jsonStr = text.substring(firstBrace, lastBrace + 1);
        print('🔍 Extracting JSON from position $firstBrace to $lastBrace');
        try {
          final result = json.decode(jsonStr) as Map<String, dynamic>;
          print('✅ JSON extracted and parsed successfully');
          return result;
        } catch (e2) {
          print('❌ Extracted JSON still invalid: $e2');
          print('Extracted text: $jsonStr');
          throw Exception('Failed to parse extracted JSON: $e2');
        }
      }
      print('❌ No JSON found in response');
      print('Response text preview: ${text.substring(0, min(500, text.length))}...');
      throw Exception('Failed to parse response: No JSON found');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: DYNAMIC PAYLOAD GENERATION (Provider-Specific)
  // ────────────────────────────────────────────────────────────────────────────

  /// Generate provider-specific request payload based on provider type
  static Map<String, dynamic> _buildRequestPayload({
    required ProviderType providerType,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> contentParts,
    int? maxTokens,
    double temperature = 0.2,
  }) {
    switch (providerType) {
      // ─ OpenAI-compatible format (OpenRouter, Groq) ─
      case ProviderType.openRouter:
      case ProviderType.groq:
        return {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': contentParts,
            },
          ],
          'max_tokens': ?maxTokens,
          'temperature': temperature,
        };

      // ─ Google Gemini REST format ─
      case ProviderType.googleAI:
        // Convert OpenAI format to Gemini format
        final List<Map<String, dynamic>> parts = [];

        // Add system prompt as the first text part
        parts.add({
          'text': systemPrompt,
        });

        // Convert content parts from OpenAI format to Gemini format
        for (final part in contentParts) {
          if (part['type'] == 'text') {
            parts.add({'text': part['text']});
          } else if (part['type'] == 'image_url') {
            final imageUrl = part['image_url']['url'] as String;
            if (imageUrl.startsWith('data:image')) {
              // Parse data URI: data:image/jpeg;base64,<base64_string>
              final dataParts = imageUrl.split(',');
              if (dataParts.length == 2) {
                final mimeTypePart = dataParts[0]; // data:image/jpeg;base64
                final base64Data = dataParts[1];
                final mimeType = mimeTypePart.split(';')[0].replaceFirst('data:', '');

                parts.add({
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Data,
                  },
                });
              }
            }
          }
        }

        return {
          'contents': [
            {
              'parts': parts,
            },
          ],
          'generationConfig': {
            'maxOutputTokens': ?maxTokens,
            'temperature': temperature,
          },
        };
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: MULTI-LEVEL FALLBACK HTTP REQUEST
  // ────────────────────────────────────────────────────────────────────────────

  /// Execute HTTP request with multi-level fallback logic
  /// Returns: (statusCode, responseBody, providerIndex)
  static Future<(int, String, int)> _executeWithFallback({
    required String systemPrompt,
    required List<Map<String, dynamic>> contentParts,
    int? maxTokens,
    double temperature = 0.2,
  }) async {
    String lastError = '';

    // Iterate through provider targets in priority order
    for (int i = 0; i < _providerTargets.length; i++) {
      final target = _providerTargets[i];

      try {
        debugPrint('🔄 Attempting Provider $i: ${target.description}');

        // Build provider-specific payload
        final payload = _buildRequestPayload(
          providerType: target.type,
          model: target.model,
          systemPrompt: systemPrompt,
          contentParts: contentParts,
          maxTokens: maxTokens,
          temperature: temperature,
        );

        // Build provider-specific headers
        final headers = _buildRequestHeaders(target.type, target.apiKey);

        // Make the HTTP request
        final response = await http.post(
          Uri.parse(target.endpoint),
          headers: headers,
          body: json.encode(payload),
        ).timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            throw Exception('Request timeout after 90 seconds');
          },
        );

        debugPrint('📊 Provider $i response status: ${response.statusCode}');

        // ─ SUCCESS: Status 200 ─
        if (response.statusCode == 200) {
          debugPrint('Provider $i succeeded');
          return (200, response.body, i);
        }

        // ─ FATAL CLIENT ERRORS: Immediate failure ─
        if (_fatalClientErrorCodes.contains(response.statusCode)) {
          debugPrint(
            'Provider $i returned fatal client error (${response.statusCode}): ${response.body}',
          );
          throw Exception(
            'Fatal error from ${target.description} (${response.statusCode}): ${response.body}',
          );
        }

        // ─ FALLBACK ERRORS: Continue to next provider ─
        if (_fallbackStatusCodes.contains(response.statusCode)) {
          debugPrint(
            'Provider $i failed with fallback status (${response.statusCode}), trying next...',
          );
          lastError = 'Provider ${i + 1} (${target.description}) failed with status ${response.statusCode}: ${response.body}';
          continue; // Try next provider
        }

        // ─ UNEXPECTED STATUS: Log and fallback ─
        debugPrint(
          'Provider $i returned unexpected status (${response.statusCode}), trying next...',
        );
        lastError = 'Provider ${i + 1} (${target.description}) returned unexpected status ${response.statusCode}';
        continue; // Try next provider
      } catch (e) {
        debugPrint(' Provider $i error: $e');
        lastError = 'Provider ${i + 1} (${target.description}) error: $e';
        // Continue to next provider
        continue;
      }
    }

    // ─ ALL PROVIDERS FAILED ─
    throw Exception(
      'All AI providers are currently unavailable. Last error: $lastError',
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: BUILD PROVIDER-SPECIFIC HEADERS
  // ────────────────────────────────────────────────────────────────────────────

  /// Build HTTP headers specific to each provider
  static Map<String, String> _buildRequestHeaders(
    ProviderType providerType,
    String apiKey,
  ) {
    switch (providerType) {
      case ProviderType.openRouter:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://jeokissan-quality-manual.web.app',
          'X-Title': 'JeoKissan QMS',
        };

      case ProviderType.googleAI:
        return {
          'Content-Type': 'application/json',
          // API key is passed as query parameter in the URL
        };

      case ProviderType.groq:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1: ANALYZE IMAGE(S) → GENERATE FOLLOW-UP QUESTIONS
  // ════════════════════════════════════════════════════════════════════════════

  /// Analyze agricultural commodity image(s) with multi-level fallback
  /// Returns a map containing:
  ///   - commodity: detected commodity name
  ///   - preliminary_assessment: visual assessment text
  ///   - questions: array of follow-up questions with dropdown options
  ///   - provider_used: index of provider that succeeded
  static Future<Map<String, dynamic>> analyzeAndAskQuestions({
    required List<Uint8List> imageBytesList,
    List<String>? fileNames,
    String languageCode = 'en', // 'en' or 'ur' for Urdu
  }) async {
    if (imageBytesList.isEmpty) {
      throw Exception('Please provide at least one image');
    }

    final String validVarieties = CommodityNameMapping.getAllCommodities().join(', ');

    // Build image content parts in OpenAI format (will be converted per provider)
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

    final systemPrompt = '''You are an expert post-harvest quality analyst for agricultural commodities.

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

CRITICAL VARIETY RULE: You MUST identify the commodity from this EXACT list of supported varieties: [$validVarieties]. Do NOT invent, guess, or output any variety that is not perfectly matching an item in this list (e.g., do not say "Mango Alphonso"). Match the visual features to the closest variety IN THE LIST. If you absolutely cannot match it to the list, output the general commodity name.

If the image IS an agricultural commodity, look at ${imageBytesList.length > 1 ? "ALL the images" : "the image"} carefully and:
1. Identify what commodity it is — DO NOT return a generic name (e.g., "Apple" or "Mango"). Deeply analyze the visual features (shape, size, color, skin texture, surface markings) and output the EXACT specific variety or cultivar from the supported list above.
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
  "commodity": "<exact specific variety or cultivar name, e.g. 'Mango Sindhri' or 'Apple Kala Kulu'>",
  "preliminary_assessment": "<1-2 sentence visual assessment>",
  "questions": [
    {"id": 1, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 2, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 3, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]},
    {"id": 4, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]},
    {"id": 5, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]}
  ]
}

IMPORTANT: Every question MUST have "type": "dropdown" and an "options" array with 3-5 relevant answer choices. Make options specific and descriptive for the commodity. ${languageCode == 'ur' ? 'تمام سوالات اور جوابات اردو میں ہوں۔' : 'All questions and answers must be in the specified language.'}''';

    // Execute with multi-level fallback
    final (statusCode, responseBody, providerIndex) = await _executeWithFallback(
      systemPrompt: systemPrompt,
      contentParts: contentParts,
      maxTokens: 700,
      temperature: 0.2,
    );

    if (statusCode != 200) {
      throw Exception('Failed to analyze image after trying all providers');
    }

    var parsed = _parseJson(responseBody);

    // Debug: Log the response for troubleshooting
    print('📋 Full API Response:');
    print(parsed.toString());

    // Check if AI rejected the image as non-agricultural
    if (parsed.containsKey('error') && parsed['error'] == 'NOT_AGRICULTURAL') {
      throw Exception(parsed['message'] ?? 'This is not an agricultural commodity image. Please upload a fruit, vegetable, grain, or other farm produce.');
    }

    if (!parsed.containsKey('questions')) {
      print('❌ Missing questions field. Available keys: ${parsed.keys.toList()}');
      
      // Extract from OpenRouter/chat completion format
      // Structure: response → choices[0] → message → content (contains JSON string)
      if (parsed.containsKey('choices')) {
        print('✓ Found choices key');
        final choices = parsed['choices'];
        print('  choices type: ${choices.runtimeType}, is List: ${choices is List}');
        
        if (choices is List && choices.isNotEmpty) {
          print('  choices is non-empty list');
          final choice = choices[0];
          print('  choice[0] type: ${choice.runtimeType}, is Map: ${choice is Map}');
          
          if (choice is Map) {
            print('  choice is a Map');
            if (choice.containsKey('message')) {
              print('  ✓ Found message key in choice');
              final message = choice['message'];
              print('    message type: ${message.runtimeType}, is Map: ${message is Map}');
              
              if (message is Map && message.containsKey('content')) {
                print('    ✓ Found content in message');
                final content = message['content'];
                print('    content type: ${content.runtimeType}, length: ${content.toString().length}');
                
                // Content is a JSON string, try to parse it
                if (content is String) {
                  print('    🔍 Content is String, parsing as JSON...');
                  try {
                    final innerJson = _parseJson(content);
                    print('    ✅ Parsed inner JSON');
                    if (innerJson.containsKey('questions')) {
                      print('    ✅ Found questions in message content!');
                      parsed = innerJson;
                      print('    ✅ Questions extracted successfully!');
                    } else {
                      print('    ⚠️ Inner JSON has no questions. Keys: ${innerJson.keys.toList()}');
                    }
                  } catch (e) {
                    print('    ⚠️ Failed to parse message content: $e');
                  }
                }
              } else {
                print('    ✗ No content found in message');
              }
            } else {
              print('  ✗ No message key in choice');
            }
          }
        }
      }
      
      // Try other common nested formats
      if (!parsed.containsKey('questions')) {
        print('  Trying fallback formats...');
        if (parsed.containsKey('data') && parsed['data'] is Map && parsed['data'].containsKey('questions')) {
          parsed['questions'] = parsed['data']['questions'];
          print('  ✅ Found questions in data format');
        } else if (parsed.containsKey('result') && parsed['result'] is Map && parsed['result'].containsKey('questions')) {
          parsed['questions'] = parsed['result']['questions'];
          print('  ✅ Found questions in result format');
        } else {
          // If we still don't have questions, throw error with more details
          throw Exception('Missing "questions" in response. Response keys: ${parsed.keys.toList()}. Full response: ${parsed.toString().substring(0, 500)}');
        }
      }
    }

    // Add provider information for monitoring
    parsed['provider_used'] = providerIndex;

    return parsed;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2: FINAL CLASSIFICATION USING IMAGE(S) + USER ANSWERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Classify agricultural commodity into 5-tier quality rating with multi-level fallback
  /// Returns a map containing:
  ///   - tier: one of [Excellent | Very Good | Good | Satisfactory | Unsatisfactory]
  ///   - confidence: confidence level (0.0-1.0)
  ///   - commodity: detected commodity name
  ///   - reasons: array of reasons for classification
  ///   - corrective_actions: array of suggested actions
  ///   - notes: optional notes
  ///   - provider_used: index of provider that succeeded
  static Future<Map<String, dynamic>> classifyWithAnswers({
    required List<Uint8List> imageBytesList,
    List<String>? fileNames,
    required String commodity,
    required List<Map<String, String>> questionsAndAnswers,
    String languageCode = 'en', // 'en' or 'ur' for Urdu
  }) async {
    if (imageBytesList.isEmpty) {
      throw Exception('Please provide at least one image');
    }

    // Format Q&A for the prompt
    final qaText = questionsAndAnswers
        .map((qa) => 'Q: ${qa["question"]}\nA: ${qa["answer"]}')
        .join('\n\n');

    // Build image content parts in OpenAI format (will be converted per provider)
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

    final systemPrompt = '''You are an expert post-harvest quality analyst for agricultural commodities.

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
}''';

    // Execute with multi-level fallback
    final (statusCode, responseBody, providerIndex) = await _executeWithFallback(
      systemPrompt: systemPrompt,
      contentParts: contentParts,
      maxTokens: 512,
      temperature: 0.1,
    );

    if (statusCode != 200) {
      throw Exception('Failed to classify image after trying all providers');
    }

    var parsed = _parseJson(responseBody);

    // Check if AI rejected the image as non-agricultural
    if (parsed.containsKey('error') && parsed['error'] == 'NOT_AGRICULTURAL') {
      throw Exception(parsed['message'] ?? 'This is not an agricultural commodity image.');
    }

    if (!parsed.containsKey('tier')) {
      print('❌ Missing tier field. Available keys: ${parsed.keys.toList()}');
      
      // Extract from OpenRouter/chat completion format
      if (parsed.containsKey('choices')) {
        print('✓ Found choices key');
        final choices = parsed['choices'];
        
        if (choices is List && choices.isNotEmpty) {
          final choice = choices[0];
          
          if (choice is Map && choice.containsKey('message')) {
            final message = choice['message'];
            
            if (message is Map && message.containsKey('content')) {
              final content = message['content'];
              print('  content type: ${content.runtimeType}');
              
              // Content is a JSON string, try to parse it
              if (content is String) {
                print('  🔍 Parsing content as JSON...');
                try {
                  final innerJson = _parseJson(content);
                  if (innerJson.containsKey('tier')) {
                    print('  ✅ Found tier in message content!');
                    parsed = innerJson;
                  } else {
                    print('  ⚠️ Inner JSON has no tier. Keys: ${innerJson.keys.toList()}');
                  }
                } catch (e) {
                  print('  ⚠️ Failed to parse message content: $e');
                }
              }
            }
          }
        }
      }
      
      // If still no tier, throw error
      if (!parsed.containsKey('tier')) {
        throw Exception('Missing "tier" in response. Available keys: ${parsed.keys.toList()}');
      }
    }

    // Add provider information for monitoring
    parsed['provider_used'] = providerIndex;

    return parsed;
  }
}
