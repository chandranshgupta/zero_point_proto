import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../services/e2ee_service.dart';
import '../../models/e2ee_payload.dart';
import '../../services/p2p_ws_transport.dart';
import '../../services/identity_service.dart';

enum MsgDirection { sent, received }
enum MsgState { active, deleted }

class ChatItem {
  final String id;
  final MsgDirection direction;
  final String encrypted;
  final String text;
  int secondsLeft;
  bool showEncrypted;
  MsgState state;
  Timer? timer;

  ChatItem({
    required this.id,
    required this.direction,
    required this.encrypted,
    required this.text,
    required this.secondsLeft,
    this.showEncrypted = false,
    this.state = MsgState.active,
    this.timer,
  });
}

class E2EEChatScreen extends StatefulWidget {
  const E2EEChatScreen({super.key});

  @override
  State<E2EEChatScreen> createState() => _E2EEChatScreenState();
}

class _E2EEChatScreenState extends State<E2EEChatScreen> {
  final _e2ee = E2EEService();
  final _transport = P2PWsTransport();
  final _identity = IdentityService();

  final _messageController = TextEditingController();
  final _peerKeyController = TextEditingController();
  final _peerIpController = TextEditingController(text: "10.0.2.2");

  String _netStatus = "Not connected";
  bool _keysReady = false;
  bool _connected = false;
  String _myPublicKeyBase64 = "Generating...";

  final List<ChatItem> _items = [];
  static int _idCounter = 0;
  String _nextId() => (++_idCounter).toString();

  final List<int> _timerOptions = [10, 30, 60, 120];
  int _selectedTimer = 30;

  int _identityRemaining = 0;
  Timer? _identityTick;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await _identity.setFlushHours(24);
    await _initKeys();
    _listenIncoming();
    _startIdentityCountdown();
  }

  Future<void> _initKeys() async {
    await _e2ee.generateKeyPair();
    if (!mounted) return;
    setState(() {
      _myPublicKeyBase64 = _e2ee.exportMyPublicKeyBase64();
    });
  }

  void _listenIncoming() {
    _transport.incoming.listen((raw) async {
      final payloadEnc = _transport.unpackPayload(raw);
      if (payloadEnc == null) return;
      if (!_e2ee.isReady) return;

      try {
        final decJson = await _e2ee.decrypt(payloadEnc);
        final map = jsonDecode(decJson) as Map<String, dynamic>;
        final parsed = E2EEPayload.fromJson(map);

        final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
        final leftMs = parsed.expiresAtMs - nowMs;
        final leftSeconds = (leftMs / 1000).ceil();
        if (leftSeconds <= 0) return;

        final item = ChatItem(
          id: parsed.id,
          direction: MsgDirection.received,
          encrypted: payloadEnc,
          text: parsed.text,
          secondsLeft: leftSeconds,
        );

        _startTimer(item);

        if (!mounted) return;
        setState(() {
          _items.insert(0, item);
        });
      } catch (e) {
        debugPrint("Receive/decrypt failed: $e");
      }
    });
  }

  Future<void> _setPeerKey() async {
    final peerKey = _peerKeyController.text.trim();
    if (peerKey.isEmpty) return;

    try {
      await _e2ee.setPeerPublicKeyBase64(peerKey);
      if (!mounted) return;

      setState(() {
        _keysReady = _e2ee.isReady;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Peer key set ✅ E2EE ready")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid peer key: $e")),
      );
    }
  }

  Future<void> _connectRelay() async {
    final ip = _peerIpController.text.trim();
    final ok = await _transport.connectToServer(ip, port: 4040);

    if (!mounted) return;
    setState(() {
      _connected = ok;
      _netStatus = ok
          ? "Connected to $ip:4040"
          : "Failed to connect to $ip:4040";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Relay connected ✅" : "Relay connection failed ❌"),
      ),
    );
  }

  void _startTimer(ChatItem item) {
    item.timer?.cancel();

    item.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (item.state == MsgState.deleted) {
        t.cancel();
        return;
      }

      setState(() {
        item.secondsLeft -= 1;
      });

      if (item.secondsLeft <= 0) {
        t.cancel();

        setState(() {
          item.state = MsgState.deleted;
          item.secondsLeft = 0;
        });

        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _items.removeWhere((m) => m.id == item.id);
          });
        });
      }
    });
  }

  void _startIdentityCountdown() {
    _identityTick?.cancel();

    _identityTick = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = await _identity.remainingSeconds();

      if (!mounted) return;
      setState(() {
        _identityRemaining = remaining;
      });

      if (remaining <= 0) {
        await _secureWipeAll(showToast: false);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identity flushed ✅ Resetting...")),
        );
        Navigator.pop(context);
      }
    });
  }

  Future<void> _secureWipeAll({bool showToast = true}) async {
    for (final m in _items) {
      m.timer?.cancel();
    }

    setState(() {
      _items.clear();
    });

    if (showToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat wiped ✅")),
      );
    }
  }

  Future<void> _flushIdentityNow() async {
    await _identity.flushIdentity();
    await _secureWipeAll(showToast: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Identity flushed ✅")),
    );
    Navigator.pop(context);
  }

  Future<void> _sendMessage() async {
    final plain = _messageController.text.trim();
    if (plain.isEmpty) return;

    if (!_e2ee.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Set peer key first")),
      );
      return;
    }

    if (!_transport.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect to relay first")),
      );
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final msgSeconds = (_identityRemaining > 0)
        ? (_selectedTimer < _identityRemaining
        ? _selectedTimer
        : _identityRemaining)
        : _selectedTimer;

    final expiresAtUtc = nowUtc.add(Duration(seconds: msgSeconds));

    final payload = E2EEPayload(
      id: _nextId(),
      text: plain,
      expiresAtMs: expiresAtUtc.millisecondsSinceEpoch,
    );

    final enc = await _e2ee.encrypt(jsonEncode(payload.toJson()));

    final item = ChatItem(
      id: payload.id,
      direction: MsgDirection.sent,
      encrypted: enc,
      text: payload.text,
      secondsLeft: msgSeconds,
    );

    _startTimer(item);

    setState(() {
      _items.insert(0, item);
      _messageController.clear();
    });

    final packed = _transport.pack(enc);
    _transport.send(packed);
  }

  String _fmt(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$h:$m:$sec";
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _messageBubble(ChatItem m) {
    final isSent = m.direction == MsgDirection.sent;
    final align = isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final bubbleColor = m.state == MsgState.deleted
        ? Colors.white10
        : (isSent ? Colors.white12 : Colors.white10);

    final title = m.state == MsgState.deleted ? "Deleted" : m.text;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                    m.state == MsgState.deleted ? Colors.white54 : Colors.white,
                    fontStyle: m.state == MsgState.deleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(isSent ? "Sent" : "Received"),
                    _chip("E2EE"),
                    _chip(
                      m.state == MsgState.deleted
                          ? "Expired"
                          : "Expires ${m.secondsLeft}s",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(() {
                      m.showEncrypted = !m.showEncrypted;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.showEncrypted ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.showEncrypted
                            ? "Hide encrypted"
                            : "Show encrypted",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (m.showEncrypted) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    m.encrypted,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    final sessionText =
    _identityRemaining > 0 ? _fmt(_identityRemaining) : "--:--:--";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(_connected ? "Connected" : "Offline"),
            _chip(_keysReady ? "E2EE Ready" : "E2EE Not Ready"),
            _chip("Session: $sessionText"),
            _chip("Msg TTL: ${_selectedTimer}s"),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Your Public Key (share to peer):",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(_myPublicKeyBase64),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _peerKeyController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Paste Peer Public Key (base64)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _setPeerKey,
          child: Text(_keysReady ? "E2EE Ready ✅" : "Set Peer Key"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _peerIpController,
          decoration: const InputDecoration(
            labelText: "Relay IP (use 10.0.2.2)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _connectRelay,
          child: const Text("Connect Relay"),
        ),
        const SizedBox(height: 6),
        Text(_netStatus, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text("Message Timer:"),
            DropdownButton<int>(
              value: _selectedTimer,
              items: _timerOptions
                  .map(
                    (s) => DropdownMenuItem(value: s, child: Text("${s}s")),
              )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedTimer = v;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final m in _items) {
      m.timer?.cancel();
    }
    _identityTick?.cancel();
    _messageController.dispose();
    _peerKeyController.dispose();
    _peerIpController.dispose();
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Secure E2EE Chat"),
        actions: [
          IconButton(
            tooltip: "Secure Wipe Chat",
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => _secureWipeAll(),
          ),
          IconButton(
            tooltip: "Flush Identity Now",
            icon: const Icon(Icons.delete_forever),
            onPressed: _flushIdentityNow,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _buildTopSection(),
            const Divider(height: 20),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No messages yet")),
              )
            else
              ..._items.map(_messageBubble),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type message…",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}