import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:jeokissan_5t_quality_management_system/commodity_name_mapping.dart';

enum ProviderType { openRouter, googleAI, groq }

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
  static List<ProviderTarget> get _providerTargets {
    var list = [
    ProviderTarget(
    type: ProviderType.openRouter,
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    model: 'google/gemma-4-31b-it:free',
    apiKey: dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '',
    description: 'OpenRouter - Gemma 4 31B Free',
    ),
    ProviderTarget(
      type: ProviderType.googleAI,
      endpoint:
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent',
      model: 'gemini-3.1-flash-lite',
      apiKey: dotenv.env['GEMINI_API_KEY']?.trim() ?? '',
      description: 'Google Gemini',
    ),
    ProviderTarget(
      type: ProviderType.groq,
      endpoint: 'https://api.groq.com/openai/v1/chat/completions',
      model: 'qwen/qwen3.8-27b',
      apiKey: dotenv.env['GROQ_API_KEY']?.trim() ?? '',
      description: 'Groq',
    ),
  ];
    return list;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: IMAGE COMPRESSION
  // ────────────────────────────────────────────────────────────────────────────

  /// Compress image to reduce payload size and improve API call speed
  static Uint8List _compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int quality = 70,
  }) {
    if (bytes.isEmpty) {
      throw const FormatException('An image is empty.');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException(
        'Could not read an image. Use a supported image format.',
      );
    }
    final oriented = img.bakeOrientation(decoded);
    final resized = max(oriented.width, oriented.height) > maxWidth
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? maxWidth : null,
            height: oriented.height > oriented.width ? maxWidth : null,
            interpolation: img.Interpolation.linear,
          )
        : oriented;
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
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
      print(
        'Response text preview: ${text.substring(0, min(500, text.length))}...',
      );
      throw Exception('Failed to parse response: No JSON found');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPER: PROVIDER-SPECIFIC REQUEST FORMATTING
  // ────────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _buildRequestPayload({
    required ProviderType providerType,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> contentParts,
    required int maxTokens,
    required double temperature,
  }) {
    if (providerType == ProviderType.googleAI) {
      final parts = <Map<String, dynamic>>[];
      for (final part in contentParts) {
        if (part['type'] == 'text') {
          parts.add({'text': part['text']});
        } else if (part['type'] == 'image_url') {
          final uri = Uri.parse(part['image_url']['url'] as String).data;
          if (uri == null) {
            throw const FormatException('Invalid inline image data.');
          }
          parts.add({
            'inlineData': {
              'mimeType': uri.mimeType,
              'data': base64Encode(uri.contentAsBytes()),
            },
          });
        }
      }
      return {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {'role': 'user', 'parts': parts},
        ],
        'generationConfig': {
          'maxOutputTokens': maxTokens,
          'temperature': temperature,
          'responseMimeType': 'application/json',
          'thinkingConfig': {'thinkingBudget': 0},
        },
      };
    }

    return {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      if (providerType == ProviderType.groq)
        'max_completion_tokens': maxTokens
      else
        'max_tokens': maxTokens,
      'temperature': temperature,
      'response_format': {'type': 'json_object'},
    };
  }

  static String _decodeResponse(String body, ProviderType providerType) {
    final envelope = json.decode(body) as Map<String, dynamic>;
    if (providerType == ProviderType.googleAI) {
      final candidates = envelope['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw const FormatException('Gemini returned no response candidate.');
      }
      final candidate = candidates.first as Map;
      final parts = candidate['content']?['parts'];
      if (candidate['finishReason'] != 'STOP' || parts is! List) {
        throw const FormatException('Gemini returned an incomplete response.');
      }
      final text = parts
          .whereType<Map>()
          .where((part) => part['thought'] != true && part['text'] is String)
          .map((part) => part['text'] as String)
          .join();
      if (text.trim().isEmpty) {
        throw const FormatException('Gemini returned no text.');
      }
      return text;
    }

    final choices = envelope['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('Provider returned no response choices.');
    }
    final choice = choices.first as Map;
    final content = choice['message']?['content'];
    if (choice['finish_reason'] != 'stop' ||
        content is! String ||
        content.trim().isEmpty) {
      throw const FormatException('Provider returned an incomplete response.');
    }
    return content;
  }

  static Map<String, String> _buildRequestHeaders(ProviderTarget target) {
    switch (target.type) {
      case ProviderType.googleAI:
        return {
          'Content-Type': 'application/json',
          'x-goog-api-key': target.apiKey,
        };
      case ProviderType.openRouter:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${target.apiKey}',
          'HTTP-Referer': 'https://jeokissan-quality-manual.web.app',
          'X-Title': 'JeoKissan QMS',
        };
      case ProviderType.groq:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${target.apiKey}',
        };
    }
  }

  static String _httpFailureMessage(
    http.Response response,
    ProviderTarget target,
  ) {
    final hint = switch (response.statusCode) {
      400 => 'request rejected; check API key, model, and request format',
      401 => 'API key rejected; create a valid key and check that it is active',
      403 => 'access denied; check provider permissions and model access',
      404 => 'model or endpoint not found',
      429 => 'provider quota or rate limit reached',
      >= 500 => 'provider service error',
      _ => 'provider rejected the request',
    };

    var detail = '';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body is Map ? body['error'] : null;
      final message = error is Map ? error['message'] : null;
      if (message is String && message.trim().isNotEmpty) {
        detail = message
            .replaceAll(target.apiKey, '[redacted]')
            .replaceAll(RegExp(r'[\r\n]+'), ' ')
            .trim();
        if (detail.length > 240) {
          detail = '${detail.substring(0, 240)}...';
        }
      }
    } on FormatException {
      // Some providers return non-JSON errors; the HTTP hint is still useful.
    }

    return '${target.description}: HTTP ${response.statusCode} ($hint)'
        '${detail.isEmpty ? '' : ' — $detail'}';
  }

  /// Execute HTTP request with multi-level fallback logic
  /// Returns: (statusCode, responseBody, providerIndex)
  static Future<(int, String, int)> _executeWithFallback({
    required String systemPrompt,
    required List<Map<String, dynamic>> contentParts,
    int? maxTokens,
    double temperature = 0.2,
  }) async {
    final failures = <String>[];
    final imageCount = contentParts
        .where((part) => part['type'] == 'image_url')
        .length;
    if (imageCount < 1 || imageCount > 4) {
      throw const FormatException('Please provide between 1 and 4 images.');
    }

    for (var index = 0; index < _providerTargets.length; index++) {
      final target = _providerTargets[index];
      if (target.apiKey.isEmpty) {
        final keyName = switch (target.type) {
          ProviderType.openRouter => 'OPENROUTER_API_KEY',
          ProviderType.googleAI => 'GEMINI_API_KEY',
          ProviderType.groq => 'GROQ_API_KEY',
        };
        debugPrint(
          '${target.description} skipped: $keyName is missing from .env',
        );
        failures.add(
          '${target.description}: $keyName is missing from the project-root .env. '
          'Add it there and fully restart Flutter.',
        );
        continue;
      }
      if (target.type == ProviderType.groq && imageCount > 3) {
        failures.add('${target.description}: supports at most 3 images');
        continue;
      }

      final client = http.Client();
      try {
        debugPrint('Trying ${target.description} (provider $index)');
        final response = await client
            .post(
              Uri.parse(target.endpoint),
              headers: _buildRequestHeaders(target),
              body: jsonEncode(
                _buildRequestPayload(
                  providerType: target.type,
                  model: target.model,
                  systemPrompt: systemPrompt,
                  contentParts: contentParts,
                  maxTokens: maxTokens ?? 1024,
                  temperature: temperature,
                ),
              ),
            )
            .timeout(const Duration(seconds: 90));

        if (response.statusCode != 200) {
          debugPrint(
            '${target.description} failed with HTTP ${response.statusCode}',
          );
          failures.add(_httpFailureMessage(response, target));
          continue;
        }

        final body = utf8.decode(response.bodyBytes);
        final text = _decodeResponse(body, target.type);
        _parseJson(text);
        return (200, text, index);
      } on FormatException {
        debugPrint('${target.description} returned an invalid response');
        failures.add('${target.description}: invalid response');
      } on http.ClientException {
        debugPrint('${target.description} network request failed');
        failures.add('${target.description}: network request failed');
      } on TimeoutException {
        debugPrint('${target.description} request timed out');
        failures.add('${target.description}: request timed out');
      } catch (error) {
        debugPrint(
          '${target.description} request failed: ${error.runtimeType}',
        );
        failures.add('${target.description}: request failed');
      } finally {
        client.close();
      }
    }

    throw Exception('No AI provider succeeded. ${failures.join('; ')}');
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
    if (imageBytesList.length > 4) {
      throw const FormatException('Please provide no more than 4 images.');
    }

    final String validVarieties = CommodityNameMapping.getAllCommodities().join(
      ', ',
    );

    // Build image content parts in OpenAI format (will be converted per provider)
    final List<Map<String, dynamic>> contentParts = [
      {
        'type': 'text',
        'text':
            'Analyze ${imageBytesList.length > 1 ? "these ${imageBytesList.length} images of the same commodity" : "this commodity image"} and generate follow-up questions to help determine its quality tier accurately. Return ONLY valid JSON.',
      },
    ];

    var encodedImageCharacters = 0;
    for (int i = 0; i < imageBytesList.length; i++) {
      // Compress image to reduce payload size and speed up API call
      final compressed = _compressImage(imageBytesList[i]);
      final base64Image = base64Encode(compressed);
      encodedImageCharacters += base64Image.length;
      if (encodedImageCharacters > 7000000) {
        throw const FormatException('Combined image data is too large.');
      }
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
      });
    }

    final systemPrompt =
        '''You are an expert post-harvest quality analyst for agricultural commodities.

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
    final (
      statusCode,
      responseBody,
      providerIndex,
    ) = await _executeWithFallback(
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
      throw Exception(
        parsed['message'] ??
            'This is not an agricultural commodity image. Please upload a fruit, vegetable, grain, or other farm produce.',
      );
    }

    if (!parsed.containsKey('questions')) {
      print(
        '❌ Missing questions field. Available keys: ${parsed.keys.toList()}',
      );

      // Extract from OpenRouter/chat completion format
      // Structure: response → choices[0] → message → content (contains JSON string)
      if (parsed.containsKey('choices')) {
        print('✓ Found choices key');
        final choices = parsed['choices'];
        print(
          '  choices type: ${choices.runtimeType}, is List: ${choices is List}',
        );

        if (choices is List && choices.isNotEmpty) {
          print('  choices is non-empty list');
          final choice = choices[0];
          print(
            '  choice[0] type: ${choice.runtimeType}, is Map: ${choice is Map}',
          );

          if (choice is Map) {
            print('  choice is a Map');
            if (choice.containsKey('message')) {
              print('  ✓ Found message key in choice');
              final message = choice['message'];
              print(
                '    message type: ${message.runtimeType}, is Map: ${message is Map}',
              );

              if (message is Map && message.containsKey('content')) {
                print('    ✓ Found content in message');
                final content = message['content'];
                print(
                  '    content type: ${content.runtimeType}, length: ${content.toString().length}',
                );

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
                      print(
                        '    ⚠️ Inner JSON has no questions. Keys: ${innerJson.keys.toList()}',
                      );
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
        if (parsed.containsKey('data') &&
            parsed['data'] is Map &&
            parsed['data'].containsKey('questions')) {
          parsed['questions'] = parsed['data']['questions'];
          print('  ✅ Found questions in data format');
        } else if (parsed.containsKey('result') &&
            parsed['result'] is Map &&
            parsed['result'].containsKey('questions')) {
          parsed['questions'] = parsed['result']['questions'];
          print('  ✅ Found questions in result format');
        } else {
          // If we still don't have questions, throw error with more details
          throw Exception(
            'Missing "questions" in response. Response keys: ${parsed.keys.toList()}. Full response: ${parsed.toString().substring(0, 500)}',
          );
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
    if (imageBytesList.length > 4) {
      throw const FormatException('Please provide no more than 4 images.');
    }

    // Format Q&A for the prompt
    final qaText = questionsAndAnswers
        .map((qa) => 'Q: ${qa["question"]}\nA: ${qa["answer"]}')
        .join('\n\n');

    // Build image content parts in OpenAI format (will be converted per provider)
    final List<Map<String, dynamic>> contentParts = [
      {
        'type': 'text',
        'text':
            'Here ${imageBytesList.length > 1 ? "are ${imageBytesList.length} images of the same" : "is the"} commodity and the user\'s answers to the follow-up questions.\n\nCommodity: $commodity\n\n$qaText\n\nNow give the FINAL 5-tier quality classification based on ${imageBytesList.length > 1 ? "all images" : "the image"} and these answers. Return ONLY valid JSON.',
      },
    ];

    var encodedImageCharacters = 0;
    for (int i = 0; i < imageBytesList.length; i++) {
      // Compress image to reduce payload size and speed up API call
      final compressed = _compressImage(imageBytesList[i]);
      final base64Image = base64Encode(compressed);
      encodedImageCharacters += base64Image.length;
      if (encodedImageCharacters > 7000000) {
        throw const FormatException('Combined image data is too large.');
      }
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
      });
    }

    final systemPrompt =
        '''You are an expert post-harvest quality analyst for agricultural commodities.

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
    final (
      statusCode,
      responseBody,
      providerIndex,
    ) = await _executeWithFallback(
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
      throw Exception(
        parsed['message'] ?? 'This is not an agricultural commodity image.',
      );
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
                    print(
                      '  ⚠️ Inner JSON has no tier. Keys: ${innerJson.keys.toList()}',
                    );
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
        throw Exception(
          'Missing "tier" in response. Available keys: ${parsed.keys.toList()}',
        );
      }
    }

    // Add provider information for monitoring
    parsed['provider_used'] = providerIndex;

    return parsed;
  }
}
