import 'package:flutter/material.dart';
import '../../services/e2ee_service.dart';

class GroupBroadcastScreen extends StatefulWidget {
  const GroupBroadcastScreen({super.key});

  @override
  State<GroupBroadcastScreen> createState() => _GroupBroadcastScreenState();
}

class _GroupBroadcastScreenState extends State<GroupBroadcastScreen> {
  final _messageController = TextEditingController();
  final _peerController = TextEditingController();

  E2EEService? _e2ee;

  final List<String> peers = [];
  final List<String> encryptedPackets = [];

  bool _loadingKeys = true;
  String _publicKeyText = "Generating...";
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initCrypto();
  }

  Future<void> _initCrypto() async {
    try {
      final service = E2EEService();
      await service.generateKeyPair();

      if (!mounted) return;

      setState(() {
        _e2ee = service;
        _publicKeyText = service.exportMyPublicKeyBase64();
        _loadingKeys = false;
        _initError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingKeys = false;
        _initError = e.toString();
      });
    }
  }

  void addPeer() {
    final key = _peerController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      peers.add(key);
    });

    _peerController.clear();
  }

  void removePeer(int index) {
    setState(() {
      peers.removeAt(index);
    });
  }

  Future<void> encryptForAll() async {
    final service = _e2ee;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Crypto not ready yet")),
      );
      return;
    }

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a message first")),
      );
      return;
    }

    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one peer first")),
      );
      return;
    }

    final packets = <String>[];

    for (final peerKey in peers) {
      try {
        await service.setPeerPublicKeyBase64(peerKey);
        final encrypted = await service.encrypt(message);
        packets.add(encrypted);
      } catch (e) {
        packets.add("Encryption failed for one peer: $e");
      }
    }

    if (!mounted) return;
    setState(() {
      encryptedPackets
        ..clear()
        ..addAll(packets);
    });
  }

  Widget _peerList() {
    if (peers.isEmpty) {
      return const Text("No peers added");
    }

    return Column(
      children: List.generate(peers.length, (index) {
        final peer = peers[index];
        return Card(
          child: ListTile(
            title: Text(
              "Peer ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              peer,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => removePeer(index),
            ),
          ),
        );
      }),
    );
  }

  Widget _packetList() {
    if (encryptedPackets.isEmpty) {
      return const Text("No encrypted packets yet");
    }

    return Column(
      children: List.generate(encryptedPackets.length, (index) {
        final packet = encryptedPackets[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Packet for Peer ${index + 1}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  packet,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _peerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _initError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Initialization failed:\n$_initError",
                textAlign: TextAlign.center,
              ),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Public Key",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _loadingKeys
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text("Generating key pair..."),
                            ],
                          )
                        : SelectableText(
                            _publicKeyText,
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Add Peer Public Key",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _peerController,
                        decoration: const InputDecoration(
                          hintText: "Paste peer public key",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addPeer,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _peerList(),
                const SizedBox(height: 20),
                const Text(
                  "Message",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Enter message",
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadingKeys ? null : encryptForAll,
                    child: const Text("Create Encrypted Packets For All"),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Encrypted Packets",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _packetList(),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text("One-to-Many Secure Chat"),
      ),
      body: body,
    );
  }
}