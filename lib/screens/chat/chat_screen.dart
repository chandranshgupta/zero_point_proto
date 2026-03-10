import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/encryption_service.dart';

class EphemeralMessage {
  final String id;
  final String encrypted;
  int secondsLeft;
  Timer? timer;

  EphemeralMessage({
    required this.id,
    required this.encrypted,
    required this.secondsLeft,
    this.timer,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final EncryptionService encryptionService = EncryptionService();

  final List<EphemeralMessage> messages = [];

  static int _idCounter = 0;
  String _nextId() => (++_idCounter).toString();

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final enc = encryptionService.encryptMessage(text);

    final msg = EphemeralMessage(
      id: _nextId(),
      encrypted: enc,
      secondsLeft: 30,
    );

    msg.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        msg.secondsLeft -= 1;
      });

      if (msg.secondsLeft <= 0) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          messages.removeWhere((m) => m.id == msg.id);
        });
      }
    });

    setState(() {
      messages.insert(0, msg);
      controller.clear();
    });
  }

  @override
  void dispose() {
    for (final m in messages) {
      m.timer?.cancel();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Chat (30s self-destruct)")),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final dec = encryptionService.decryptMessage(m.encrypted);

                      return ListTile(
                        title: Text(dec),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText("Encrypted: ${m.encrypted}"),
                            Text("Self-destruct in: ${m.secondsLeft}s"),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}