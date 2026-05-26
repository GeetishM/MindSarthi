import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'journal_entry.dart';

class JournalAIService {
  static String getApiKey() {
    // 1. Try environment define
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    // 2. Try Hive settings box (deprecated fallback)
    final box = Hive.box('journalSettings');
    return box.get('GROQ_API_KEY', defaultValue: '') as String;
  }

  static void saveApiKey(String key) {
    final box = Hive.box('journalSettings');
    box.put('GROQ_API_KEY', key.trim());
  }

  static Future<Map<String, dynamic>?> transcribeAudio(String audioPath) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      throw Exception("API_KEY_MISSING");
    }

    try {
      // 1. Send audio to Groq Whisper for raw transcription
      final whisperUri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', whisperUri);
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));
      request.fields['model'] = 'whisper-large-v3';
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send();
      final whisperResponse = await http.Response.fromStream(streamedResponse);

      if (whisperResponse.statusCode != 200) {
        throw Exception('Groq Whisper error (${whisperResponse.statusCode}): ${whisperResponse.body}');
      }

      final whisperData = json.decode(whisperResponse.body);
      final rawText = whisperData['text'] as String?;
      if (rawText == null || rawText.trim().isEmpty) {
        return null;
      }

      // 2. Send raw text to Groq Llama 3.1 to format into structured JSON
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final chatResponse = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional assistant. You must format the user\'s raw transcription into a beautifully structured JSON object. '
                  'The output JSON must contain exactly these three fields:\n'
                  '1. "title": A short, creative title (3-5 words) summarizing the tone or content.\n'
                  '2. "content": The complete, detailed transcription, formatted nicely with paragraphs.\n'
                  '3. "tags": A list of 2-3 relevant topic tags (lowercase, e.g. ["reflection", "mindfulness"]).\n'
                  'Return ONLY the raw JSON string. Do not wrap in markdown or markdown codeblocks.'
            },
            {
              'role': 'user',
              'content': rawText
            }
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (chatResponse.statusCode == 200) {
        final chatData = json.decode(utf8.decode(chatResponse.bodyBytes));
        final jsonText = chatData['choices'][0]['message']['content'].toString().trim();
        return json.decode(jsonText) as Map<String, dynamic>;
      } else {
        throw Exception('Groq Llama error (${chatResponse.statusCode}): ${chatResponse.body}');
      }
    } catch (e) {
      debugPrint("Transcribe error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> analyzeSentiment(String contentText) async {
    final apiKey = getApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'Analyze the sentiment of the journal entry. '
                  'You must return a JSON object containing exactly these fields:\n'
                  '1. "score": A number from 1 to 10 (overall mood: 1 is extremely distressed, 10 is happy/peaceful).\n'
                  '2. "emotions": A list of 1-3 primary emotional tags (e.g. ["Anxious", "Joyful", "Reflective"]).\n'
                  '3. "recommendation": A supportive self-care advice (max 2 sentences).\n'
                  '4. "crisis_flag": A boolean (true if indicating self-harm, suicide, or severe emergency, else false).\n'
                  'Return ONLY the raw JSON string. Do not wrap in markdown or markdown codeblocks.'
            },
            {
              'role': 'user',
              'content': contentText
            }
          ],
          'temperature': 0.2,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final chatData = json.decode(utf8.decode(response.bodyBytes));
        final jsonText = chatData['choices'][0]['message']['content'].toString().trim();
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
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final List<Map<String, dynamic>> messages = [];
      messages.add({
        'role': 'system',
        'content': "You are 'Digital Reflection', a gentle, insightful conversational journaling companion for the MindSarthi app. "
            "Your goal is to help the user explore their thoughts, feelings, and experiences through structured, empathetic reflection.\n"
            "Guidelines:\n"
            "1. Validate their feelings: show empathy and warmth.\n"
            "2. Keep responses brief: 1 or 2 sentences max. Do not dominate the conversation.\n"
            "3. Ask ONE open-ended, gentle follow-up question that helps them explore their feelings or thoughts deeper.\n"
            "4. Act as a mirror; do not give immediate direct advice or solutions unless they ask.\n"
            "5. If they express severe distress or self-harm, keep a supportive tone but gently remind them to seek help or call crisis support."
      });

      // Add chat history
      for (var msg in chatHistory) {
        final role = msg['role'] == 'user' ? 'user' : 'assistant';
        messages.add({
          'role': role,
          'content': msg['message'] ?? ''
        });
      }

      // Add user message
      messages.add({
        'role': 'user',
        'content': userMessage
      });

      final response = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 150
        }),
      );

      if (response.statusCode == 200) {
        final chatData = json.decode(utf8.decode(response.bodyBytes));
        return chatData['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Groq error: ${response.body}');
      }
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
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final formattedHistory = chatHistory.map((msg) {
        final role = msg['role'] == 'user' ? 'User' : 'Digital Reflection';
        return "$role: ${msg['message']}";
      }).join('\n');

      final response = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'Analyze this conversational reflection journal between a user and their Digital Reflection companion. '
                  'Compile the conversation into a structured journal entry format.\n\n'
                  'You must return a JSON object with exactly the following fields:\n'
                  '1. "title": A short, creative title (3-5 words) summarizing the core topic or tone.\n'
                  '2. "summary": A beautiful, cohesive narrative summary (3-5 sentences) of the user\'s feelings, reflections, and insights.\n'
                  '3. "tags": A list of 2-3 relevant topic tags (lowercase, e.g. ["reflection", "work-stress"]).\n'
                  '4. "score": A sentiment score from 1 to 10 (where 1 is highly distressed, 5 is neutral, 10 is joyful/peaceful).\n'
                  '5. "emotions": A list of 1-3 primary emotions detected (e.g. ["Reflective", "Anxious", "Grateful"]).\n'
                  '6. "recommendation": A supportive self-care advice sentence tailored to this conversation.\n'
                  '7. "crisis_flag": A boolean indicating if the content contains self-harm or psychiatric emergencies.\n\n'
                  'Return ONLY the raw JSON string. Do not wrap in markdown or markdown codeblocks.'
            },
            {
              'role': 'user',
              'content': formattedHistory
            }
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final chatData = json.decode(utf8.decode(response.bodyBytes));
        final jsonText = chatData['choices'][0]['message']['content'].toString().trim();
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
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

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

      final response = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are the MindSarthi "Pattern Analyst", a system designed to spot long-term behavioral, emotional, and cognitive patterns across multiple journal entries.\n'
                  'Analyze the following list of chronological journal entries to extract actionable, deep insights about the user.\n\n'
                  'Look for:\n'
                  '- Weekly trends (e.g., "Mood dips on Tuesdays", "Highly active and peaceful on weekends").\n'
                  '- Emotional loops (e.g., "Self-criticism spikes after work-related anxiety").\n'
                  '- Triggers (e.g., specific names, meetings, events, or tags correlating with lower mood scores).\n'
                  '- Positive drivers (e.g., "Nature or family references correlate with mood scores of 8+").\n'
                  '- Empathic, actionable guidance based on these patterns.\n\n'
                  'Format your response in beautiful, premium Markdown with clear headers, bullet points, and highlighted insights (use bold formatting). Do not use HTML tags in the output. Start directly with the analysis content.'
            },
            {
              'role': 'user',
              'content': formattedEntries
            }
          ],
          'temperature': 0.4
        }),
      );

      if (response.statusCode == 200) {
        final chatData = json.decode(utf8.decode(response.bodyBytes));
        return chatData['choices'][0]['message']['content'].toString().trim();
      }
    } catch (e) {
      debugPrint("Recursive pattern analysis error: $e");
    }
    return null;
  }
}
