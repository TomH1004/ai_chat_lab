import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepLService {
  Future<String?> translateText({
    required String apiKey,
    required String text,
    required String targetLang,
    String sourceLang = 'AUTO',
    bool useFreeApi = true,
  }) async {
    if (apiKey.isEmpty || text.trim().isEmpty) return null;

    final base = useFreeApi ? 'https://api-free.deepl.com' : 'https://api.deepl.com';
    final uri = Uri.parse('$base/v2/translate');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'DeepL-Auth-Key $apiKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'text': text,
          'target_lang': targetLang,
          if (sourceLang.isNotEmpty && sourceLang.toUpperCase() != 'AUTO')
            'source_lang': sourceLang,
          'preserve_formatting': '1',
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        final translations = jsonBody['translations'] as List<dynamic>?;
        if (translations != null && translations.isNotEmpty) {
          return translations.first['text']?.toString();
        }
        return null;
      } else {
        // Swallow errors and return null to avoid blocking the main save flow
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}


