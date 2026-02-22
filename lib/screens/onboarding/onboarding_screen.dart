import 'package:flutter/material.dart';
import '../home/dashboard_screen.dart';
import '../../services/identity_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final identity = IdentityService();
  final timerController = TextEditingController(text: "24");
  String status = "";

  @override
  void initState() {
    super.initState();
    _autoGoIfValid();
  }

  Future<void> _autoGoIfValid() async {
    final ok = await identity.hasValidIdentity();
    if (ok && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _create() async {
    final hours = int.tryParse(timerController.text.trim()) ?? 24;
    await identity.createIdentity(hours: hours);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 90),
              const SizedBox(height: 14),
              const Text(
                "Ghost Entry",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Identity Flush Timer (hours)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _create,
                child: const Text("Create Anonymous Identity"),
              ),
              const SizedBox(height: 10),
              Text(status),
            ],
          ),
        ),
      ),
    );
  }
}