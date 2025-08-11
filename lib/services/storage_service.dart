import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chat_lab/services/deepl_service.dart';

class StorageService {
  
  Future<bool> isSavingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('save_conversations') ?? false;
  }

  Future<void> setSavingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_conversations', enabled);
  }

  Future<void> saveConversation(String participantId, String userMessage, String agentResponse) async {
    if (!await isSavingEnabled()) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final chatDir = Directory('${directory.path}/convai_chats');
      
      if (!await chatDir.exists()) {
        await chatDir.create(recursive: true);
      }

      final timestamp = DateTime.now();
      final dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final baseName = 'chat_${participantId.isNotEmpty ? participantId : 'default'}_$dateStr';
      final file = File('${chatDir.path}/$baseName.txt');

      final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
      final entry = '\n[$timeStr]\nparticipant: "$userMessage"\nagent: "$agentResponse"\n';

      await file.writeAsString(entry, mode: FileMode.append);

      // Also save DeepL-translated variant if enabled/configured
      final prefs = await SharedPreferences.getInstance();
      final deeplEnabled = prefs.getBool('deepl_enabled') ?? false;
      final deeplApiKey = prefs.getString('deepl_api_key') ?? '';
      final deeplUseFree = prefs.getBool('deepl_use_free') ?? true;
      final deeplTargetLang = (prefs.getString('deepl_target_lang') ?? 'EN').toUpperCase();
      final deeplSourceLang = (prefs.getString('deepl_source_lang') ?? 'AUTO').toUpperCase();

      if (deeplEnabled && deeplApiKey.isNotEmpty) {
        final deepl = DeepLService();
        final translatedUser = await deepl.translateText(
          apiKey: deeplApiKey,
          text: userMessage,
          targetLang: deeplTargetLang,
          sourceLang: deeplSourceLang,
          useFreeApi: deeplUseFree,
        );
        final translatedAgent = await deepl.translateText(
          apiKey: deeplApiKey,
          text: agentResponse,
          targetLang: deeplTargetLang,
          sourceLang: deeplSourceLang,
          useFreeApi: deeplUseFree,
        );

        if ((translatedUser ?? '').isNotEmpty || (translatedAgent ?? '').isNotEmpty) {
          final translatedFile = File('${chatDir.path}/$baseName.${deeplTargetLang.toLowerCase()}.txt');
          final entryTranslated = '\n[$timeStr]\nparticipant: "${translatedUser ?? userMessage}"\nagent: "${translatedAgent ?? agentResponse}"\n';
          await translatedFile.writeAsString(entryTranslated, mode: FileMode.append);
        }
      }
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  Future<List<File>> getChatFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final chatDir = Directory('${directory.path}/convai_chats');
      
      if (!await chatDir.exists()) {
        return [];
      }

      final files = await chatDir.list().where((entity) => entity is File && entity.path.endsWith('.txt')).cast<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      print('Error getting chat files: $e');
      return [];
    }
  }

  Future<String> getChatDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/convai_chats';
  }
}
