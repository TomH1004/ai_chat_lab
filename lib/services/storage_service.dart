import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final fileName = 'chat_${participantId.isNotEmpty ? participantId : 'default'}_$dateStr.txt';
      final file = File('${chatDir.path}/$fileName');

      final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
      final entry = '\n[$timeStr]\nparticipant: "$userMessage"\nagent: "$agentResponse"\n';

      await file.writeAsString(entry, mode: FileMode.append);
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
