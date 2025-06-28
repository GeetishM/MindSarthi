import 'dart:convert';
import 'package:flutter/services.dart';

class HelplineService {
  static Map<String, String>? _helplineNumbers;

  static Future<void> loadHelplineNumbers() async {
    if (_helplineNumbers != null) return;

    final String jsonString = await rootBundle.loadString(
      'lib/personal/pages/1homepage/panic_sos/helpline.json',
    );

    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _helplineNumbers =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<String?> getStateHelpline(String state) async {
    await loadHelplineNumbers();
    return _helplineNumbers?[state];
  }

  static Future<String?> getNationalHelpline() async {
    await loadHelplineNumbers();
    return _helplineNumbers?['national_helpline'];
  }
}
