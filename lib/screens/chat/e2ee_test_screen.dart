import 'package:flutter/material.dart';
import '../../services/e2ee_service.dart';

class E2EETestScreen extends StatefulWidget {
  const E2EETestScreen({super.key});

  @override
  State<E2EETestScreen> createState() => _E2EETestScreenState();
}

class _E2EETestScreenState extends State<E2EETestScreen> {
  final userA = E2EEService();
  final userB = E2EEService();

  bool ready = false;
  String encrypted = "Not tested yet";
  String decrypted = "Not tested yet";
  String status = "Initializing...";

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      await userA.generateKeyPair();
      await userB.generateKeyPair();

      // ✅ Exchange public keys using base64 export/import
      final aPub = userA.exportMyPublicKeyBase64();
      final bPub = userB.exportMyPublicKeyBase64();

      await userA.setPeerPublicKeyBase64(bPub);
      await userB.setPeerPublicKeyBase64(aPub);

      setState(() {
        ready = true;
        status = "Ready ✅";
      });
    } catch (e) {
      setState(() {
        status = "Init failed: $e";
      });
    }
  }

  Future<void> testEncryption() async {
    if (!ready) return;

    try {
      final enc = await userA.encrypt("Hello Secure World");
      final dec = await userB.decrypt(enc);

      setState(() {
        encrypted = enc;
        decrypted = dec;
      });
    } catch (e) {
      setState(() {
        decrypted = "Decrypt failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E2EE Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: ready ? testEncryption : null,
              child: const Text("Test E2EE"),
            ),
            const SizedBox(height: 20),
            const Text("Encrypted:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(encrypted),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Decrypted:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(decrypted),
          ],
        ),
      ),
    );
  }
}