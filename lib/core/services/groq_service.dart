import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/utility/local_rag_engine.dart';

class GroqService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  // Fallback API key loaded from compile-time environment.
  static String groqApiKey = const String.fromEnvironment('GROQ_API_KEY'); 

  /// Sends a chat message history to Groq Llama 3 and streams/returns the response.
  static Future<String> getChatResponse({
    required List<Map<String, String>> history,
    required String userMessage,
    required String apiKey,
  }) async {
    final activeKey = apiKey.isNotEmpty ? apiKey : groqApiKey;
    if (activeKey.isEmpty) {
      throw Exception('Groq API Key is missing. Please configure it.');
    }

    // Retrieve RAG Context using our local Hive database knowledge-base
    final ragContext = LocalRagEngine.retrieveContext(userMessage);

    final List<Map<String, String>> messages = [];

    // Inject system instructions with RAG context
    final systemMessage = 
        "You are Sarthi, a warm, highly empathetic, and supportive mental wellness companion. "
        "Your mission is to act as a caring friend and gentle active listener, never a cold machine or clinical diagnostic tool. "
        "RULES:\n"
        "1. Active Listening & Mirroring: Mirror the user's emotion first (e.g., 'I hear how painful this is for you', 'It sounds like you are carrying a lot of stress right now').\n"
        "2. Validation: Normalize and validate their feelings without immediately rushing to 'fix' everything. Let them know they are not alone.\n"
        "3. Empathy-First Tone: Keep your voice warm, understanding, and companion-like. Avoid clinical jargon or lecturing.\n"
        "4. Concise Support: Keep responses concise (max 3-4 sentences) so they are easy to read during vulnerable times.\n"
        "5. Subtly suggest relevant app features (like writing in the 'Journal', logging feelings in the 'Mood Input', trying breathing/grounding in 'Relief Resources', or looking up contacts in 'Helpline') only if they fit the discussion naturally.\n"
        "${ragContext != null ? 'Use this specific context to support your advice: $ragContext' : ''}";

    messages.add({"role": "system", "content": systemMessage});
    
    // Add chat history (format: role: user/assistant, content: text)
    messages.addAll(history);
    
    // Add current user message
    messages.add({"role": "user", "content": userMessage});

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $activeKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', // Ultra-fast Llama 3.1 model running on Groq LPUs
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Groq API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq request failed: $e');
      rethrow;
    }
  }
}
