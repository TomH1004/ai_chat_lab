import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConvaiService {
  static const String _baseUrl = 'https://api.convai.com/character/getResponse';
  
  String _apiKey = '';
  String _characterId = '';
  String _sessionId = '-1';

  // Remove default values for security - users must set their own
  static const String defaultApiKey = '';
  static const String defaultCharacterId = '';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? defaultApiKey;
    _characterId = prefs.getString('character_id') ?? defaultCharacterId;
  }

  Future<void> saveSettings(String apiKey, String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
    await prefs.setString('character_id', characterId);
    _apiKey = apiKey;
    _characterId = characterId;
  }

  String get apiKey => _apiKey;
  String get characterId => _characterId;

  bool get isConfigured => _apiKey.isNotEmpty && _characterId.isNotEmpty;

  void resetSession() {
    _sessionId = '-1';
  }

  Future<String> sendMessage(String userText) async {
    if (_apiKey.isEmpty || _characterId.isEmpty) {
      throw Exception('API key or Character ID not set. Please check settings.');
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Add headers
      request.headers['CONVAI-API-KEY'] = _apiKey;
      
      // Add form fields
      request.fields['userText'] = userText;
      request.fields['charID'] = _characterId;
      request.fields['sessionID'] = _sessionId;
      request.fields['voiceResponse'] = 'False';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _sessionId = data['sessionID'] ?? _sessionId;
        return data['text'] ?? 'No response received';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get list of saved character IDs
  Future<List<String>> getSavedCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saved_characters') ?? [];
  }

  // Save a new character ID
  Future<void> saveCharacter(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final characters = await getSavedCharacters();
    if (!characters.contains(characterId)) {
      characters.add(characterId);
      await prefs.setStringList('saved_characters', characters);
    }
  }

  // Remove a character ID
  Future<void> removeCharacter(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final characters = await getSavedCharacters();
    characters.remove(characterId);
    await prefs.setStringList('saved_characters', characters);
  }
}
