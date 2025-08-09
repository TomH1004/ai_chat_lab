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

    // Clean up name and initial prompt entries for this character
    final names = await _getCharacterNamesMap();
    if (names.remove(characterId) != null) {
      await _setCharacterNamesMap(names);
    }
    final prompts = await _getCharacterInitialPromptsMap();
    if (prompts.remove(characterId) != null) {
      await _setCharacterInitialPromptsMap(prompts);
    }
  }

  // Rename an existing character ID and migrate associated name and initial prompt
  Future<void> renameCharacterId(String oldCharacterId, String newCharacterId) async {
    final oldId = oldCharacterId.trim();
    final newId = newCharacterId.trim();
    if (newId.isEmpty) {
      throw Exception('New character ID cannot be empty');
    }
    if (oldId == newId) return;

    final prefs = await SharedPreferences.getInstance();
    final characters = await getSavedCharacters();
    if (!characters.contains(oldId)) {
      throw Exception('Character not found');
    }
    if (characters.contains(newId)) {
      throw Exception('A character with this ID already exists');
    }

    // Replace in list preserving order
    final index = characters.indexOf(oldId);
    characters[index] = newId;
    await prefs.setStringList('saved_characters', characters);

    // Migrate name
    final names = await _getCharacterNamesMap();
    if (names.containsKey(oldId)) {
      names[newId] = names[oldId] ?? '';
      names.remove(oldId);
      await _setCharacterNamesMap(names);
    }

    // Migrate initial prompt
    final prompts = await _getCharacterInitialPromptsMap();
    if (prompts.containsKey(oldId)) {
      prompts[newId] = prompts[oldId] ?? '';
      prompts.remove(oldId);
      await _setCharacterInitialPromptsMap(prompts);
    }

    // Update current configured character if it matches
    if (_characterId == oldId) {
      await prefs.setString('character_id', newId);
      _characterId = newId;
    }
  }

  // Character names management
  Future<Map<String, String>> _getCharacterNamesMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('character_names_json');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  Future<void> _setCharacterNamesMap(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('character_names_json', json.encode(map));
  }

  Future<String> getCharacterName(String characterId) async {
    final map = await _getCharacterNamesMap();
    return map[characterId] ?? '';
  }

  Future<void> setCharacterName(String characterId, String name) async {
    final map = await _getCharacterNamesMap();
    if (name.isEmpty) {
      map.remove(characterId);
    } else {
      map[characterId] = name;
    }
    await _setCharacterNamesMap(map);
  }

  Future<Map<String, String>> getAllCharacterNames() async {
    return _getCharacterNamesMap();
  }

  // Character initial prompts management
  Future<Map<String, String>> _getCharacterInitialPromptsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('character_initial_prompts_json');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  Future<void> _setCharacterInitialPromptsMap(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('character_initial_prompts_json', json.encode(map));
  }

  Future<String> getCharacterInitialPrompt(String characterId) async {
    final map = await _getCharacterInitialPromptsMap();
    return map[characterId] ?? '';
  }

  Future<void> setCharacterInitialPrompt(String characterId, String prompt) async {
    final map = await _getCharacterInitialPromptsMap();
    if (prompt.isEmpty) {
      map.remove(characterId);
    } else {
      map[characterId] = prompt;
    }
    await _setCharacterInitialPromptsMap(map);
  }

  // Supervised mode
  Future<bool> isSupervisedModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('supervised_mode') ?? false;
  }

  Future<void> setSupervisedModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('supervised_mode', enabled);
  }

  // Timed experiment settings
  Future<bool> isTimedExperimentEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('timed_experiment_enabled') ?? false;
  }

  Future<void> setTimedExperimentEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timed_experiment_enabled', enabled);
  }

  Future<int> getExperimentDurationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('experiment_duration_minutes') ?? 5;
  }

  Future<void> setExperimentDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('experiment_duration_minutes', minutes);
  }
}
