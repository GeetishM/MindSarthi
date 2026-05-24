import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  // Fallback API key loaded from compile-time environment.
  static String groqApiKey = const String.fromEnvironment('GROQ_API_KEY'); 

  /// Scans the user message for emotional keywords and returns matching coping instructions.
  /// This acts as a lightweight local RAG (Retrieval-Augmented Generation) context.
  static String? getLocalRagContext(String message) {
    final lowerMessage = message.toLowerCase();

    // 1. Anxiety / Panic Grounding
    if (lowerMessage.contains('panic') || 
        lowerMessage.contains('anxious') || 
        lowerMessage.contains('anxiety') || 
        lowerMessage.contains('scared') || 
        lowerMessage.contains('nervous') ||
        lowerMessage.contains('heart is beating fast')) {
      return "CONSTRUCTIVE COPING ACTION: The user is showing signs of anxiety or panic. "
          "Gently guide them to perform the '5-4-3-2-1 Grounding Technique': "
          "Acknowledge 5 things they can see, 4 things they can touch, 3 things they can hear, 2 things they can smell, and 1 thing they can taste. "
          "Encourage slow, deep belly breathing.";
    }

    // 2. Crisis / Self-Harm Prevention
    if (lowerMessage.contains('suicide') || 
        lowerMessage.contains('kill myself') || 
        lowerMessage.contains('self-harm') || 
        lowerMessage.contains('die') || 
        lowerMessage.contains('hurt myself') || 
        lowerMessage.contains('give up on life')) {
      return "URGENT CRISIS ACTION: The user is expressing thoughts of self-harm or suicide. "
          "Provide immediate, unconditional emotional support in a warm, non-judgmental tone. "
          "Clearly, gently, and explicitly encourage them to contact support resources: "
          "Provide the national helpline number (988 for US/Canada, 112 for Europe, or local equivalent). "
          "Do not lecture, and remind them that they are not alone and that help is available.";
    }

    // 3. Sadness / Loneliness
    if (lowerMessage.contains('sad') || 
        lowerMessage.contains('lonely') || 
        lowerMessage.contains('depressed') || 
        lowerMessage.contains('crying') || 
        lowerMessage.contains('hopeless') ||
        lowerMessage.contains('heartbroken')) {
      return "CONSTRUCTIVE COPING ACTION: The user is experiencing sadness or isolation. "
          "Focus on validating their feelings without trying to 'fix' everything immediately. "
          "Recommend one simple self-care step, like drinking a warm glass of water, going for a short 5-minute walk, or doing a gentle stretching exercise.";
    }

    // No specific keyword hit
    return null;
  }

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

    // Scan for RAG context
    final ragContext = getLocalRagContext(userMessage);

    final List<Map<String, String>> messages = [];

    // Inject system instructions with RAG context
    final systemMessage = "You are MindSarthi, a warm, highly empathetic, and professional mental wellness companion. "
        "Your goal is to actively listen, validate user feelings, and offer calm, supportive guidance based on cognitive behavioral therapy (CBT) principles. "
        "Keep responses friendly, helpful, and concise (max 3-4 sentences). "
        "Avoid clinical jargon, and never diagnose medical conditions. "
        "${ragContext ?? ''}";

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
          'model': 'llama3-8b-8192', // Ultra-fast Llama 3 model running on Groq LPUs
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
