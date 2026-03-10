import 'package:flutter/material.dart';

import '../chat/chat_screen.dart';
import '../chat/e2ee_chat_screen.dart';
import '../chat/e2ee_test_screen.dart';
import '../chat/group_broadcast_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../stealth/calculator_screen.dart';
import '../../services/identity_service.dart';

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

    if (!mounted) return;

    setState(() {
      alias = a;
      expiryText = e?.toLocal().toString() ?? "No expiry";
    });

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

  Widget _menuButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(title),
          ),
        ),
      ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alias: $alias",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Flush At: $expiryText",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _menuButton(
                title: "Open Chat (AES Demo)",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),

              _menuButton(
                title: "Stealth Mode (Calculator)",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CalculatorScreen(),
                    ),
                  );
                },
              ),

              _menuButton(
                title: "Test Real E2EE",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const E2EETestScreen()),
                  );
                },
              ),

              _menuButton(
                title: "Open Real E2EE Chat",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const E2EEChatScreen()),
                  );
                },
              ),

              _menuButton(
                title: "One-to-Many Secure Chat",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupBroadcastScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}