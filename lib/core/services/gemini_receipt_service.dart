import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiReceiptService {
  GeminiReceiptService({required String apiKey})
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

  final GenerativeModel _model;

  Future<Map<String, dynamic>> parseReceipt(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw const GeminiReceiptServiceException('Receipt OCR text is empty.');
    }

    final GenerateContentResponse response;
    try {
      response = await _model.generateContent(<Content>[
        Content.text(_buildPrompt(rawText)),
      ]);
      debugPrint('===== GEMINI RESPONSE =====');
      debugPrint(response.text);
      debugPrint('===========================');
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        GeminiReceiptServiceException('Failed to parse receipt with Gemini: $error'),
        stackTrace,
      );
    }

    final String? responseText = response.text;
    if (responseText == null || responseText.trim().isEmpty) {
      throw const GeminiReceiptServiceException(
        'Gemini returned an empty receipt parsing response.',
      );
    }

    return _decodeReceiptJson(responseText);
  }

  String _buildPrompt(String rawText) {
  return '''
You are an AI specialized in extracting receipt information.

Extract the receipt data from the OCR text.

Return ONLY valid JSON with this exact structure:

{
  "merchant": "string",
  "date": "YYYY-MM-DD",
  "category": "Dine In | Take Away | Digital Wallet | Grocery | Transportation | Entertainment | Other",
  "total": number,
  "items": [
    {
      "name": "string",
      "price": number
    }
  ]
}

Rules:

- merchant = business/store/restaurant name.
- date = convert into YYYY-MM-DD.
- total = final amount paid.
- items = purchased products or services only.
- Ignore receipt headers, reference numbers, payment codes, customer names, addresses and footer text.

Category Rules:
- Restaurant, Cafe, Food Court -> Dine In
- Take Away restaurant -> Take Away
- DANA, OVO, GoPay, ShopeePay Top Up -> Digital Wallet
- Indomaret, Alfamart, Supermarket -> Grocery
- Pertamina, SPBU -> Transportation
- XXI, CGV -> Entertainment
- Otherwise -> Other

If OCR contains obvious spelling mistakes, infer the correct word.

Return ONLY JSON.

OCR TEXT:
"""
$rawText
"""
''';
  }

  Map<String, dynamic> _decodeReceiptJson(String responseText) {
    final String jsonText = _extractJsonObject(responseText);

    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException catch (error) {
      throw GeminiReceiptServiceException(
        'Gemini returned invalid JSON: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const GeminiReceiptServiceException(
        'Gemini JSON response must be an object.',
      );
    }

    _validateReceiptJson(decoded);
    return decoded;
  }

  String _extractJsonObject(String responseText) {
    final String trimmed = responseText.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final RegExpMatch? fencedMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fencedMatch != null) {
      return fencedMatch.group(1)!.trim();
    }

    final int objectStart = trimmed.indexOf('{');
    final int objectEnd = trimmed.lastIndexOf('}');
    if (objectStart != -1 && objectEnd > objectStart) {
      return trimmed.substring(objectStart, objectEnd + 1).trim();
    }

    throw GeminiReceiptServiceException(
      'Gemini response did not contain a JSON object: $trimmed',
    );
  }

  void _validateReceiptJson(Map<String, dynamic> value) {
    const Set<String> requiredKeys = <String>{'merchant', 'date', 'category', 'total', 'items',};
    final Set<String> missingKeys = requiredKeys.difference(value.keys.toSet());
    if (missingKeys.isNotEmpty) {
      throw GeminiReceiptServiceException(
        'Gemini JSON response is missing required keys: ${missingKeys.join(', ')}.',
      );
    }

    if (value['merchant'] is! String) {
      throw const GeminiReceiptServiceException(
        'Gemini JSON response key "merchant" must be a string.',
      );
    }

    if (value['date'] is! String) {
     throw const GeminiReceiptServiceException(
      'Gemini JSON response key "date" must be a string.',
     );
    }

    if (value['category'] is! String) {
     throw const GeminiReceiptServiceException(
      'Gemini JSON response key "category" must be a string.',
     );
    }

    if (value['total'] is! num) {
      throw const GeminiReceiptServiceException(
        'Gemini JSON response key "total" must be a number.',
      );
    }

    final Object? items = value['items'];
    if (items is! List) {
      throw const GeminiReceiptServiceException(
        'Gemini JSON response key "items" must be a list.',
      );
    }

    for (final Object? item in items) {
      if (item is! Map<String, dynamic>) {
        throw const GeminiReceiptServiceException(
          'Each Gemini receipt item must be a JSON object.',
        );
      }

      if (item['name'] is! String) {
        throw const GeminiReceiptServiceException(
          'Each Gemini receipt item must include a string "name".',
        );
      }

      if (item['price'] is! num) {
        throw const GeminiReceiptServiceException(
          'Each Gemini receipt item must include a numeric "price".',
        );
      }
    }
  }
}

class GeminiReceiptServiceException implements Exception {
  const GeminiReceiptServiceException(this.message);

  final String message;

  @override
  String toString() => 'GeminiReceiptServiceException: $message';
}
