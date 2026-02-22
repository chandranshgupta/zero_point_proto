import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../stealth/calculator_screen.dart';
import '../chat/e2ee_test_screen.dart';
import '../chat/e2ee_chat_screen.dart';
import '../../services/identity_service.dart';
import '../onboarding/onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final identity = IdentityService();
  String alias = "Loading...";
  String expiryText = "Loading...";

  @override
  void initState() {
    super.initState();
    loadIdentity();
  }

  Future<void> loadIdentity() async {
    final a = await identity.getAlias();
    final e = await identity.getExpiry();

    setState(() {
      alias = a ?? "No identity";
      expiryText = e?.toString() ?? "No expiry";
    });

    // Auto flush if expired
    final ok = await identity.hasValidIdentity();
    if (!ok && mounted) {
      await identity.flushIdentity();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> flushNow() async {
    await identity.flushIdentity();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: flushNow,
            icon: const Icon(Icons.delete_forever),
            tooltip: "Flush Identity",
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Alias: $alias", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Text("Flush At: $expiryText", style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 24),

              ElevatedButton(
                child: const Text("Open Chat (AES demo)"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
                },
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                child: const Text("Stealth Mode (Calculator)"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
                },
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                child: const Text("Test Real E2EE"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const E2EETestScreen()));
                },
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                child: const Text("Open Real E2EE Chat"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const E2EEChatScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}