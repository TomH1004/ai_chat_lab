import 'package:flutter/material.dart';
import 'package:ai_chat_lab/screens/chat_screen.dart';
import 'package:ai_chat_lab/screens/setup_screen.dart';
import 'package:ai_chat_lab/services/convai_service.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final ConvaiService _convaiService = ConvaiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  void _checkConfiguration() async {
    await _convaiService.loadSettings();
    
    setState(() {
      _isLoading = false;
    });

    // Navigate to appropriate screen
    if (mounted) {
      if (_convaiService.isConfigured) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4F8CFF),
                borderRadius: BorderRadius.circular(20),
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
              'Convai Chat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F8CFF)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
