import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'journal_entry.dart';
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

  static Future<Map<String, dynamic>?> analyzeSentiment(String contentText) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([
        Content.text(
          "Analyze the sentiment of this journal entry. "
          "Return a JSON object with: "
          "1. 'score': (a number from 1 to 10, representing overall mood where 1 is extremely distressed and 10 is extremely happy/peaceful). "
          "2. 'emotions': (a list of 1-3 primary emotional tags detected, e.g. ['Anxious', 'Joyful', 'Reflective']). "
          "3. 'recommendation': (a supportive self-care advice, max 2 sentences). "
          "4. 'crisis_flag': (a boolean, true if content indicates self-harm, suicide, or severe psychiatric emergency, else false). "
          "Return only the raw JSON. Here is the entry content:\n$contentText"
        )
      ]);

      final jsonText = response.text;
      if (jsonText != null && jsonText.isNotEmpty) {
        return json.decode(jsonText) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Sentiment analysis error: $e");
    }
    return null;
  }

  static Future<String?> getShadowJournalFollowUp({
    required String userMessage,
    required List<Map<String, String>> chatHistory,
  }) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      throw Exception("API_KEY_MISSING");
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final formattedHistory = chatHistory.map((msg) {
        final role = msg['role'] == 'user' ? 'User' : 'Digital Reflection';
        return "$role: ${msg['message']}";
      }).join('\n');

      final prompt = "You are 'Digital Reflection', a gentle, insightful conversational journaling companion for the MindSarthi app. "
          "Your goal is to help the user explore their thoughts, feelings, and experiences through structured, empathetic reflection. "
          "Guidelines:\n"
          "1. Validate their feelings: show empathy and warmth.\n"
          "2. Keep responses brief: 1 or 2 sentences max. Do not dominate the conversation.\n"
          "3. Ask ONE open-ended, gentle follow-up question that helps them explore their feelings or thoughts deeper.\n"
          "4. Act as a mirror; do not give immediate direct advice or solutions unless they ask.\n"
          "5. If they express severe distress or self-harm, keep a supportive tone but gently remind them to seek help or call crisis support.\n\n"
          "Here is the conversation history so far:\n"
          "$formattedHistory\n\n"
          "User's latest response: \"$userMessage\"\n\n"
          "Provide your next response as 'Digital Reflection':";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      debugPrint("Shadow journal follow-up error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> generateShadowJournalSummary(
      List<Map<String, String>> chatHistory) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final formattedHistory = chatHistory.map((msg) {
        final role = msg['role'] == 'user' ? 'User' : 'Digital Reflection';
        return "$role: ${msg['message']}";
      }).join('\n');

      final prompt = "Analyze this conversational reflection journal between a user and their Digital Reflection companion. "
          "Compile the conversation into a structured journal entry format.\n\n"
          "You must return a JSON object with exactly the following fields:\n"
          "1. 'title': A short, creative title (3-5 words) summarizing the core topic or tone.\n"
          "2. 'summary': A beautiful, cohesive narrative summary (3-5 sentences) of the user's feelings, reflections, and insights.\n"
          "3. 'tags': A list of 2-3 relevant topic tags (lowercase, e.g. [\"reflection\", \"work-stress\"]).\n"
          "4. 'score': A sentiment score from 1 to 10 (where 1 is highly distressed, 5 is neutral, 10 is joyful/peaceful).\n"
          "5. 'emotions': A list of 1-3 primary emotions detected (e.g. [\"Reflective\", \"Anxious\", \"Grateful\"]).\n"
          "6. 'recommendation': A supportive self-care advice sentence tailored to this conversation.\n"
          "7. 'crisis_flag': A boolean indicating if the content contains self-harm or psychiatric emergencies.\n\n"
          "Conversation transcript:\n"
          "$formattedHistory\n\n"
          "Return only the raw JSON.";

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonText = response.text;
      if (jsonText != null && jsonText.isNotEmpty) {
        return json.decode(jsonText) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Shadow journal summary error: $e");
    }
    return null;
  }

  static Future<String?> performRecursivePatternAnalysis(List<JournalEntry> entries) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final formattedEntries = entries.map((entry) {
        final dateStr = "${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}";
        final weekdays = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
        final weekdayName = weekdays[entry.createdAt.weekday];
        
        final sentimentStr = entry.sentimentScore != null ? "${entry.sentimentScore!.toStringAsFixed(1)}/10" : "N/A";
        final emotionsStr = entry.sentimentEmotions?.join(', ') ?? "N/A";
        final tagsStr = entry.tag.join(', ');

        return "Date: $dateStr ($weekdayName)\n"
            "Title: ${entry.title}\n"
            "Tags: $tagsStr\n"
            "Mood Score: $sentimentStr\n"
            "Emotions: $emotionsStr\n"
            "Content: ${entry.content}\n"
            "---";
      }).join('\n\n');

      final prompt = "You are the MindSarthi 'Pattern Analyst', a system designed to spot long-term behavioral, emotional, and cognitive patterns across multiple journal entries.\n"
          "Analyze the following list of chronological journal entries to extract actionable, deep insights about the user.\n\n"
          "Look for:\n"
          "- Weekly trends (e.g., 'Mood tends to dip on Tuesdays', 'Highly active and peaceful on weekends').\n"
          "- Emotional loops (e.g., 'Self-criticism spikes after work-related anxiety', 'Anxiety followed by reflective writing').\n"
          "- Triggers (e.g., specific names, meetings, events, or tags correlating with lower mood scores).\n"
          "- Positive drivers (e.g., 'Nature or family references correlate with mood scores of 8+').\n"
          "- Empathic, actionable guidance based on these patterns.\n\n"
          "Format your response in beautiful, premium Markdown with clear headers, bullet points, and highlighted insights (use bold formatting). Do not use HTML tags in the output. Start directly with the analysis content.\n\n"
          "Journal Entries:\n"
          "$formattedEntries";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      debugPrint("Recursive pattern analysis error: $e");
    }
    return null;
  }
}
