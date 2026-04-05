import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class GeminiClassificationService {
  // ── Firebase Cloud Functions Reference ───────────────────────────────
  static final _functions = FirebaseFunctions.instance;

  // ── Cloud Function Names ────────────────────────────────────────────
  static const String _analyzeAndAskQuestionsFunction = 'analyze_and_ask_questions';
  static const String _classifyWithAnswersFunction = 'classify_with_answers';

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

  // ── Helper: Call Cloud Function with error handling ─────────────────
  static Future<Map<String, dynamic>> _callCloudFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final response = await callable.call(data);
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response type from Cloud Function: ${response.data.runtimeType}');
      }
    } on Exception catch (e) {
      // Handle all exceptions
      debugPrint('Cloud Function error: $e');
      
      final message = e.toString();
      if (message.contains('unauthenticated')) {
        throw Exception('You must be logged in to use this feature');
      } else if (message.contains('invalid-argument')) {
        throw Exception(e.toString());
      } else if (message.contains('NOT_AGRICULTURAL')) {
        throw Exception(e.toString());
      } else {
        throw Exception('Error: ${e.toString()}');
      }
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
    if (imageBytesList.isEmpty) {
      throw Exception('Please provide at least one image');
    }

    // Compress all images and convert to base64
    final List<String> base64Images = [];
    for (final imageBytes in imageBytesList) {
      final compressed = _compressImage(imageBytes);
      final base64Image = base64Encode(compressed);
      base64Images.add('data:image/jpeg;base64,$base64Image');
    }

    // Call Cloud Function
    final result = await _callCloudFunction(
      _analyzeAndAskQuestionsFunction,
      {
        'base64_images': base64Images,
        'language_code': languageCode,
      },
    );

    // Validate response structure
    if (!result.containsKey('questions')) {
      throw Exception('Missing "questions" in response');
    }
    if (!result.containsKey('commodity')) {
      throw Exception('Missing "commodity" in response');
    }

    return result;
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
    if (imageBytesList.isEmpty) {
      throw Exception('Please provide at least one image');
    }
    if (commodity.trim().isEmpty) {
      throw Exception('Commodity name is required');
    }

    // Compress all images and convert to base64
    final List<String> base64Images = [];
    for (final imageBytes in imageBytesList) {
      final compressed = _compressImage(imageBytes);
      final base64Image = base64Encode(compressed);
      base64Images.add('data:image/jpeg;base64,$base64Image');
    }

    // Call Cloud Function
    final result = await _callCloudFunction(
      _classifyWithAnswersFunction,
      {
        'base64_images': base64Images,
        'commodity': commodity,
        'questions_and_answers': questionsAndAnswers,
        'language_code': languageCode,
      },
    );

    // Validate response structure
    if (!result.containsKey('tier')) {
      throw Exception('Missing "tier" in response');
    }

    return result;
  }
}
