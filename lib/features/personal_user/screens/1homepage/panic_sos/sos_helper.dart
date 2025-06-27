import 'dart:convert';
import 'package:flutter/services.dart';

class HelplineService {
  static Future<Map<String, dynamic>> loadHelplineNumbers() async {
    // Load JSON file as a string
    String jsonString = await rootBundle.loadString('lib/personal/pages/1homepage/panic_sos/helpline.json');
    
    // Decode JSON string into a Map
    Map<String, dynamic> jsonData = json.decode(jsonString);
    
    return jsonData;
  }

  // Get national helpline number
  static Future<String> getNationalHelpline() async {
    Map<String, dynamic> data = await loadHelplineNumbers();
    return data["national_helpline"];
  }

  // Get helpline number for a specific state
  static Future<String?> getStateHelpline(String stateName) async {
    Map<String, dynamic> data = await loadHelplineNumbers();
    List<dynamic> states = data["states"];

    for (var state in states) {
      if (state["name"].toLowerCase() == stateName.toLowerCase()) {
        return state["helpline"];
      }
    }
    return null; // Return null if state is not found
  }
}
