import 'package:flutter/material.dart';
import 'package:ai_chat_lab/services/convai_service.dart';
import 'package:ai_chat_lab/screens/chat_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _characterIdController = TextEditingController();
  final ConvaiService _convaiService = ConvaiService();
  
  bool _showApiKey = false;
  bool _isLoading = false;

  void _completeSetup() async {
    final apiKey = _apiKeyController.text.trim();
    final characterId = _characterIdController.text.trim();

    if (apiKey.isEmpty) {
      _showError('Please enter your API key');
      return;
    }

    if (characterId.isEmpty) {
      _showError('Please enter a character ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save settings
      await _convaiService.saveSettings(apiKey, characterId);
      
      // Save the character to the character management list
      await _convaiService.saveCharacter(characterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to chat screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    } catch (e) {
      _showError('Error saving settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Welcome Header
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F8CFF), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F8CFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Welcome to AI Chat Lab!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Setup Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: API Key',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get your API key from convai.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_showApiKey,
                      decoration: InputDecoration(
                        labelText: 'Convai API Key',
                        hintText: 'Enter your API key',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F8CFF), width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showApiKey ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(() => _showApiKey = !_showApiKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Step 2: Choose a Character',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find character IDs in your Convai dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _characterIdController,
                      decoration: InputDecoration(
                        labelText: 'Character ID',
                        hintText: 'Enter character ID to chat with',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E7EF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F8CFF), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Help Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8CFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4F8CFF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8CFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Visit convai.com to create your account and get your API key. You can change these settings anytime later.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Chatting',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _characterIdController.dispose();
    super.dispose();
  }
}
