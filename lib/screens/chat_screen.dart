import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_chat_lab/services/convai_service.dart';
import 'package:ai_chat_lab/services/storage_service.dart';
import 'package:ai_chat_lab/screens/settings_screen.dart';
import 'package:ai_chat_lab/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _participantController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConvaiService _convaiService = ConvaiService();
  final StorageService _storageService = StorageService();
  
  List<ChatMessage> messages = [];
  bool isLoading = false;
  String participantId = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    await _convaiService.loadSettings();
    setState(() {});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _convaiService.sendMessage(text);
      
      setState(() {
        messages.add(ChatMessage(text: response, isUser: false));
        isLoading = false;
      });

      // Save conversation if enabled
      if (await _storageService.isSavingEnabled()) {
        await _storageService.saveConversation(participantId, text, response);
      }
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(text: 'Error: ${e.toString()}', isUser: false));
        isLoading = false;
      });
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text(
            'This will clear all messages and start a new session with the character. Are you sure?',
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
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      setState(() {
        messages.clear();
      });
      _convaiService.resetSession();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat cleared and new session started'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Convai Chat',
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
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadSettings());
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Participant ID input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E7EF)),
              ),
            ),
            child: TextField(
              controller: _participantController,
              onChanged: (value) => participantId = value,
              decoration: InputDecoration(
                labelText: 'Participant ID',
                hintText: 'Enter participant ID for this session',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4F8CFF), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ),

          // Chat messages
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Thinking...'),
                              ],
                            ),
                          );
                        }
                        
                        final message = messages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: message.isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: message.isUser
                                      ? const Color(0xFF4F8CFF)
                                      : const Color(0xFFF1F5FB),
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: message.isUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                    bottomLeft: message.isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: message.isUser
                                        ? Colors.white
                                        : const Color(0xFF2D3748),
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (KeyEvent event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          if (!HardwareKeyboard.instance.isShiftPressed) {
                            // Enter without Shift - send message
                            _sendMessage();
                          }
                          // Shift+Enter - allow new line (default behavior)
                        }
                      }
                    },
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message... (Enter to send, Shift+Enter for new line)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF4F8CFF), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F8CFF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _participantController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
