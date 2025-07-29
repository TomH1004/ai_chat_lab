import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chat_lab/services/convai_service.dart';
import 'package:ai_chat_lab/services/storage_service.dart';
import 'package:ai_chat_lab/screens/chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _characterIdController = TextEditingController();
  final TextEditingController _newCharacterController = TextEditingController();
  
  final ConvaiService _convaiService = ConvaiService();
  final StorageService _storageService = StorageService();
  
  bool _savingEnabled = false;
  List<String> _savedCharacters = [];
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    await _convaiService.loadSettings();
    _apiKeyController.text = _convaiService.apiKey;
    _characterIdController.text = _convaiService.characterId;
    
    final saving = await _storageService.isSavingEnabled();
    final characters = await _convaiService.getSavedCharacters();
    
    setState(() {
      _savingEnabled = saving;
      _savedCharacters = characters;
    });
  }

  void _saveSettings() async {
    try {
      await _convaiService.saveSettings(
        _apiKeyController.text.trim(),
        _characterIdController.text.trim(),
      );
      await _storageService.setSavingEnabled(_savingEnabled);
      
      // If there's a character ID, save it to the character management list
      final characterId = _characterIdController.text.trim();
      if (characterId.isNotEmpty) {
        await _convaiService.saveCharacter(characterId);
        // Reload settings to refresh the character list
        _loadSettings();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to chat if properly configured
        if (_convaiService.isConfigured) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCharacter() async {
    final characterId = _newCharacterController.text.trim();
    if (characterId.isNotEmpty) {
      await _convaiService.saveCharacter(characterId);
      _newCharacterController.clear();
      _loadSettings();
    }
  }

  void _removeCharacter(String characterId) async {
    await _convaiService.removeCharacter(characterId);
    _loadSettings();
  }

  void _selectCharacter(String characterId) {
    setState(() {
      _characterIdController.text = characterId;
    });
  }

  void _showChatDirectory() async {
    final directory = await _storageService.getChatDirectory();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chat Files Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chat files are saved in:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  directory,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: directory));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard')),
                );
              },
              child: const Text('Copy Path'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _resetAllData() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'This will delete all settings, saved characters, and chat files. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset All'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      try {
        // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Clear text controllers
        _apiKeyController.clear();
        _characterIdController.clear();
        _newCharacterController.clear();

        // Reset state
        setState(() {
          _savingEnabled = false;
          _savedCharacters = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been reset'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3748),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Configuration
            _buildSection(
              'API Configuration',
              [
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your Convai API key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _characterIdController,
                  decoration: InputDecoration(
                    labelText: 'Current Character ID',
                    hintText: 'Enter character ID to chat with',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Character Management
            _buildSection(
              'Character Management',
              [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCharacterController,
                        decoration: InputDecoration(
                          labelText: 'Add New Character',
                          hintText: 'Enter character ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCharacter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8CFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_savedCharacters.isNotEmpty) ...[
                  const Text(
                    'Saved Characters:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_savedCharacters.map((character) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E7EF)),
                    ),
                    child: ListTile(
                      title: Text(
                        character,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: character));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Character ID copied')),
                              );
                            },
                            tooltip: 'Copy ID',
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, size: 20, color: Color(0xFF4F8CFF)),
                            onPressed: () => _selectCharacter(character),
                            tooltip: 'Use this character',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _removeCharacter(character),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  ))),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Chat Settings
            _buildSection(
              'Chat Settings',
              [
                SwitchListTile(
                  title: const Text('Save Conversations'),
                  subtitle: const Text('Save chat history to text files'),
                  value: _savingEnabled,
                  onChanged: (value) => setState(() => _savingEnabled = value),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE0E7EF)),
                  ),
                ),
                if (_savingEnabled) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showChatDirectory,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Show Chat Files Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F8CFF),
                      side: const BorderSide(color: Color(0xFF4F8CFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Reset Section
            _buildSection(
              'Reset & Data',
              [
                ElevatedButton.icon(
                  onPressed: _resetAllData,
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text('Reset All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will clear all settings, saved characters, and preferences.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Information Section
            _buildSection(
              'Information',
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Format:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'participant: "user message"\nagent: "bot response"',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Files are saved as: chat_[participantID]_YYYY-MM-DD.txt',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _characterIdController.dispose();
    _newCharacterController.dispose();
    super.dispose();
  }
}