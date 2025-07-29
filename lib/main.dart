import 'package:flutter/material.dart';
import 'package:ai_chat_lab/screens/startup_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convai Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const StartupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
