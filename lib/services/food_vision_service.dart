/// Food photo → nutrition estimation via Google Gemini (multimodal).
///
/// Sends the image (base64 inline) + a strict-JSON prompt to the Gemini
/// `generateContent` REST endpoint and parses per-item macros.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// One estimated food item from a photo.
class FoodEstimate {
  const FoodEstimate({
    required this.name,
    required this.serving,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final String name;
  final String serving;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  factory FoodEstimate.fromJson(Map<String, dynamic> j) => FoodEstimate(
        name: (j['name'] ?? 'Makanan').toString(),
        serving: (j['serving'] ?? '1 porsi').toString(),
        calories: _d(j['calories']),
        proteinG: _d(j['proteinG'] ?? j['protein']),
        carbG: _d(j['carbG'] ?? j['carbs'] ?? j['carb']),
        fatG: _d(j['fatG'] ?? j['fat']),
      );

  static double _d(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class FoodVisionResult {
  const FoodVisionResult({required this.items, this.note = ''});
  final List<FoodEstimate> items;
  final String note;

  double get totalCalories => items.fold(0, (s, e) => s + e.calories);
  double get totalProtein => items.fold(0, (s, e) => s + e.proteinG);
}

class FoodVisionException implements Exception {
  FoodVisionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FoodVisionService {
  FoodVisionService({this.model = 'gemini-1.5-flash'});

  final String model;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const _prompt = '''
You are a precise nutrition estimator. Analyze the food in this photo.
Identify each distinct food item and estimate the visible portion size.
Return ONLY valid JSON with this exact schema (no prose, no markdown):
{
  "foods": [
    {"name": string, "serving": string, "calories": number,
     "proteinG": number, "carbG": number, "fatG": number}
  ],
  "note": string
}
Use realistic values for the visible portion. "note" is a short (max 12 words)
Indonesian confidence remark, e.g. "Perkiraan: nasi + ayam bakar, porsi sedang".
If no food is visible, return {"foods": [], "note": "Tidak ada makanan terdeteksi"}.
''';

  /// Estimates nutrition from raw image bytes.
  /// Throws [FoodVisionException] on missing key, network, or parse failure.
  Future<FoodVisionResult> analyze(Uint8List imageBytes,
      {required String apiKey, String mimeType = 'image/jpeg'}) async {
    if (apiKey.trim().isEmpty) {
      throw FoodVisionException(
          'API key Gemini belum diisi. Buka Pengaturan → Food AI.');
    }

    final uri = Uri.parse('$_endpoint/$model:generateContent?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    });

    http.Response resp;
    try {
      resp = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw FoodVisionException('Gagal menghubungi Gemini: $e');
    }

    if (resp.statusCode != 200) {
      throw FoodVisionException(
          'Gemini error ${resp.statusCode}: ${_short(resp.body)}');
    }

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = (((data['candidates'] as List?)?.first
              as Map<String, dynamic>?)?['content'] as Map<String, dynamic>?)?['parts'];
      String jsonText = '';
      if (text is List && text.isNotEmpty) {
        jsonText = (text.first as Map<String, dynamic>)['text']?.toString() ?? '';
      }
      if (jsonText.isEmpty) {
        throw FoodVisionException('Respons Gemini kosong.');
      }
      final parsed = jsonDecode(_stripFence(jsonText)) as Map<String, dynamic>;
      final foods = (parsed['foods'] as List?) ?? [];
      final items = foods
          .whereType<Map<String, dynamic>>()
          .map(FoodEstimate.fromJson)
          .toList();
      return FoodVisionResult(
        items: items,
        note: (parsed['note'] ?? '').toString(),
      );
    } on FoodVisionException {
      rethrow;
    } catch (e) {
      throw FoodVisionException('Gagal membaca respons Gemini: $e');
    }
  }

  String _stripFence(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }

  String _short(String s) => s.length > 200 ? '${s.substring(0, 200)}…' : s;
}
