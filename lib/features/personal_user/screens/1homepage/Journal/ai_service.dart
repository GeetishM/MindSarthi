import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/api/api_service.dart';

class JournalAIService {
  static String getApiKey() {
    // 1. Try static apiKey
    if (ApiService.apiKey.isNotEmpty) {
      return ApiService.apiKey;
    }
    // 2. Try Hive settings box
    final box = Hive.box('journalSettings');
    return box.get('GEMINI_API_KEY', defaultValue: '') as String;
  }

  static void saveApiKey(String key) {
    final box = Hive.box('journalSettings');
    box.put('GEMINI_API_KEY', key.trim());
  }

  static Future<Map<String, dynamic>?> transcribeAudio(String audioPath) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      throw Exception("API_KEY_MISSING");
    }

    try {
      final bytes = await File(audioPath).readAsBytes();
      final audioPart = DataPart('audio/aac', Uint8List.fromList(bytes));

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([
        Content.multi([
          audioPart,
          TextPart(
            "Transcribe this voice note into a beautifully formatted journal entry. "
            "You must return a JSON object with exactly three fields: "
            "1. 'title': A short, creative title (3-5 words) summarizing the tone or content of the entry. "
            "2. 'content': The complete, detailed transcription, formatted nicely with paragraphs if it's long. "
            "3. 'tags': A list of 2-3 relevant topic tags (without the # symbol, e.g., ['reflection', 'mindfulness']). "
            "Return only the raw JSON. Example: "
            "{\"title\": \"Morning Calmness\", \"content\": \"Today I woke up feeling very peaceful...\", \"tags\": [\"peace\", \"morning\"]}"
          ),
        ]),
      ]);

      final jsonText = response.text;
      if (jsonText != null && jsonText.isNotEmpty) {
        return json.decode(jsonText) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Transcribe error: $e");
      rethrow;
    }
    return null;
  }
}
