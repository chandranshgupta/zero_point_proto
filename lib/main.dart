import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StealthChatApp());
}

class StealthChatApp extends StatelessWidget {
  const StealthChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stealth Chat',
      theme: AppTheme.darkTheme,
      home: const OnboardingScreen(),
    );
  }
}