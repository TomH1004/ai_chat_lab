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
  final TextEditingController _characterNameController = TextEditingController();
  final TextEditingController _initialPromptController = TextEditingController();
  final TextEditingController _newCharacterNameController = TextEditingController();
  final TextEditingController _newCharacterPromptController = TextEditingController();
  
  final ConvaiService _convaiService = ConvaiService();
  final StorageService _storageService = StorageService();
  
  // DeepL
  final TextEditingController _deeplApiKeyController = TextEditingController();
  bool _deeplEnabled = false;
  bool _deeplUseFreeApi = true;
  String _deeplSourceLang = 'AUTO';
  String _deeplTargetLang = 'EN';
  
  bool _savingEnabled = false;
  bool _supervisedMode = false;
  bool _timedExperiment = false;
  int _experimentDuration = 5;
  List<String> _savedCharacters = [];
  Map<String, String> _characterNames = {};
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _convaiService.loadSettings();
    _apiKeyController.text = _convaiService.apiKey;
    _characterIdController.text = _convaiService.characterId;
    
    final saving = await _storageService.isSavingEnabled();
    final characters = await _convaiService.getSavedCharacters();
    final supervised = await _convaiService.isSupervisedModeEnabled();
    final timedExperiment = await _convaiService.isTimedExperimentEnabled();
    final duration = await _convaiService.getExperimentDurationMinutes();
    final names = await _convaiService.getAllCharacterNames();
    final selectedPrompt = await _convaiService.getCharacterInitialPrompt(_convaiService.characterId);
    final prefs = await SharedPreferences.getInstance();
    final deeplEnabled = prefs.getBool('deepl_enabled') ?? false;
    final deeplApiKey = prefs.getString('deepl_api_key') ?? '';
    final deeplUseFree = prefs.getBool('deepl_use_free') ?? true;
    final deeplSource = prefs.getString('deepl_source_lang') ?? 'AUTO';
    final deeplTarget = prefs.getString('deepl_target_lang') ?? 'EN';
    
    setState(() {
      _savingEnabled = saving;
      _savedCharacters = characters;
      _supervisedMode = supervised;
      _timedExperiment = timedExperiment;
      _experimentDuration = duration;
      _characterNames = names;
      _initialPromptController.text = selectedPrompt;
      _deeplEnabled = deeplEnabled;
      _deeplApiKeyController.text = deeplApiKey;
      _deeplUseFreeApi = deeplUseFree;
      _deeplSourceLang = deeplSource;
      _deeplTargetLang = deeplTarget;
    });

    _characterNameController.text = names[_characterIdController.text.trim()] ?? '';
  }

  Future<void> _applySelectedCharacterChange() async {
    final id = _characterIdController.text.trim();
    _characterNameController.text = await _convaiService.getCharacterName(id);
    _initialPromptController.text = await _convaiService.getCharacterInitialPrompt(id);
    setState(() {});
  }

  void _saveSettings() async {
    try {
      await _convaiService.saveSettings(
        _apiKeyController.text.trim(),
        _characterIdController.text.trim(),
      );
      await _storageService.setSavingEnabled(_savingEnabled);
      await _convaiService.setSupervisedModeEnabled(_supervisedMode);
      await _convaiService.setTimedExperimentEnabled(_timedExperiment);
      await _convaiService.setExperimentDurationMinutes(_experimentDuration);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('deepl_enabled', _deeplEnabled);
      await prefs.setString('deepl_api_key', _deeplApiKeyController.text.trim());
      await prefs.setBool('deepl_use_free', _deeplUseFreeApi);
      await prefs.setString('deepl_source_lang', _deeplSourceLang.toUpperCase());
      await prefs.setString('deepl_target_lang', _deeplTargetLang.toUpperCase());
      
      // Save name/prompt for current character if provided
      final currentId = _characterIdController.text.trim();
      if (currentId.isNotEmpty) {
        await _convaiService.saveCharacter(currentId);
        await _convaiService.setCharacterName(currentId, _characterNameController.text.trim());
        await _convaiService.setCharacterInitialPrompt(currentId, _initialPromptController.text.trim());
        // Reload settings to refresh lists and maps
        await _loadSettings();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
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
    final characterName = _newCharacterNameController.text.trim();
    final characterPrompt = _newCharacterPromptController.text.trim();
    if (characterId.isNotEmpty) {
      await _convaiService.saveCharacter(characterId);
      if (characterName.isNotEmpty) {
        await _convaiService.setCharacterName(characterId, characterName);
      }
      if (characterPrompt.isNotEmpty) {
        await _convaiService.setCharacterInitialPrompt(characterId, characterPrompt);
      }
      _newCharacterController.clear();
      _newCharacterNameController.clear();
      _newCharacterPromptController.clear();
      _loadSettings();
    }
  }

  void _removeCharacter(String characterId) async {
    await _convaiService.removeCharacter(characterId);
    _loadSettings();
  }

  void _selectCharacter(String characterId) async {
    setState(() {
      _characterIdController.text = characterId;
    });
    await _applySelectedCharacterChange();
  }

  Future<void> _editCharacter(String characterId) async {
    final existingName = await _convaiService.getCharacterName(characterId);
    final existingPrompt = await _convaiService.getCharacterInitialPrompt(characterId);
    final idController = TextEditingController(text: characterId);
    final nameController = TextEditingController(text: existingName);
    final promptController = TextEditingController(text: existingPrompt);

    if (!mounted) return;
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Avatar', style: const TextStyle(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Character ID',
                    hintText: 'Unique character ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('Display Name and Prompt', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Detective Bot',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Initial Prompt',
                    hintText: 'Optional first-turn prompt (used in Supervised Mode)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      final newId = idController.text.trim();
      try {
        if (newId != characterId) {
          await _convaiService.renameCharacterId(characterId, newId);
          // Keep selection in form in sync if this was the current selection
          if (_characterIdController.text.trim() == characterId) {
            _characterIdController.text = newId;
          }
          characterId = newId;
        }
        await _convaiService.setCharacterName(characterId, nameController.text.trim());
        await _convaiService.setCharacterInitialPrompt(characterId, promptController.text.trim());
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        _apiKeyController.clear();
        _characterIdController.clear();
        _newCharacterController.clear();
        _characterNameController.clear();
        _initialPromptController.clear();
        _newCharacterNameController.clear();
        _newCharacterPromptController.clear();

        setState(() {
          _savingEnabled = false;
          _supervisedMode = false;
          _timedExperiment = false;
          _experimentDuration = 5;
          _savedCharacters = [];
          _characterNames = {};
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
                  onChanged: (_) => _applySelectedCharacterChange(),
                  decoration: InputDecoration(
                    labelText: 'Current Character ID',
                    hintText: 'Enter character ID to chat with',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _characterNameController,
                  decoration: InputDecoration(
                    labelText: 'Character Name (for your reference)',
                    hintText: 'e.g., Detective Bot',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              'Character Management',
              [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _newCharacterController,
                        decoration: InputDecoration(
                          labelText: 'New Character ID',
                          hintText: 'Enter character ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _newCharacterNameController,
                        decoration: InputDecoration(
                          labelText: 'Name (optional)',
                          hintText: 'e.g., Detective Bot',
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
                const SizedBox(height: 12),
                TextField(
                  controller: _newCharacterPromptController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'Initial Prompt (optional)',
                    hintText: 'First message sent when using Supervised Mode',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                            _characterNames[character]?.isNotEmpty == true
                                ? '${_characterNames[character]}'
                                : character,
                            style: _characterNames[character]?.isNotEmpty == true
                                ? const TextStyle()
                                : const TextStyle(fontFamily: 'monospace'),
                          ),
                          subtitle: _characterNames[character]?.isNotEmpty == true
                              ? Text('ID: $character', style: const TextStyle(fontFamily: 'monospace'))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                                onPressed: () => _editCharacter(character),
                                tooltip: 'Edit name/prompt',
                              ),
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
                      )))
                ],
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              'Initial Prompt (per character)',
              [
                TextField(
                  controller: _initialPromptController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'Initial Prompt',
                    hintText: 'Optional system-style message to send as the first turn when supervised mode is enabled',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'When Supervised Mode is ON, the first turn will use this prompt and the user must press Start Experiment.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 24),

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
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('DeepL: Save translated copy'),
                  subtitle: const Text('Create an additional file translated via DeepL'),
                  value: _deeplEnabled,
                  onChanged: (value) => setState(() => _deeplEnabled = value),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE0E7EF)),
                  ),
                ),
                if (_deeplEnabled) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deeplApiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'DeepL API Key',
                      hintText: 'Enter your DeepL API key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _deeplSourceLang,
                          items: _deeplLanguageCodes(includeAuto: true)
                              .map((code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _deeplSourceLang = (v ?? 'AUTO').toUpperCase()),
                          decoration: InputDecoration(
                            labelText: 'Source Language',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _deeplTargetLang,
                          items: _deeplLanguageCodes()
                              .where((c) => c != 'AUTO')
                              .map((code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _deeplTargetLang = (v ?? 'EN').toUpperCase()),
                          decoration: InputDecoration(
                            labelText: 'Target Language',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _deeplUseFreeApi,
                        onChanged: (v) => setState(() => _deeplUseFreeApi = v ?? true),
                      ),
                      const Text('Use api-free.deepl.com (Free tier)'),
                    ],
                  ),
                ],
                SwitchListTile(
                  title: const Text('Supervised Mode'),
                  subtitle: const Text('Disable typing for first message; require Start Experiment'),
                  value: _supervisedMode,
                  onChanged: (value) => setState(() => _supervisedMode = value),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE0E7EF)),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Timed Experiment'),
                  subtitle: const Text('Hide messages after time limit expires'),
                  value: _timedExperiment,
                  onChanged: (value) => setState(() => _timedExperiment = value),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE0E7EF)),
                  ),
                ),
                if (_timedExperiment) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Duration:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      Container(
                        width: 80,
                        child: DropdownButtonFormField<int>(
                          value: _experimentDuration,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [1, 2, 3, 5, 10, 15, 20, 30].map((minutes) {
                            return DropdownMenuItem<int>(
                              value: minutes,
                              child: Text('$minutes'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _experimentDuration = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('minutes'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chat will be hidden after the time limit expires from the first message.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
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
    _characterNameController.dispose();
    _initialPromptController.dispose();
    _newCharacterNameController.dispose();
    _newCharacterPromptController.dispose();
    _deeplApiKeyController.dispose();
    super.dispose();
  }

  List<String> _deeplLanguageCodes({bool includeAuto = false}) {
    // List of DeepL supported target codes (as of 2024-2025). Keep concise.
    final codes = <String>[
      'BG','CS','DA','DE','EL','EN','ES','ET','FI','FR','HU','ID','IT','JA','KO','LT','LV','NB','NL','PL','PT','RO','RU','SK','SL','SV','TR','UK','ZH'
    ];
    if (includeAuto) return ['AUTO', ...codes];
    return codes;
  }
}