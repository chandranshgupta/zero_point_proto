import 'dart:async';
import 'dart:convert';
import 'dart:io';

class P2PWsTransport {
  WebSocket? _socket;
  final _incomingController = StreamController<String>.broadcast();

  Stream<String> get incoming => _incomingController.stream;
  bool get isConnected => _socket != null;

  Future<bool> connectToServer(String ip, {int port = 4040}) async {
    try {
      _socket = await WebSocket.connect('ws://$ip:$port');

      _socket!.listen(
        (data) => _incomingController.add(data.toString()),
        onDone: () {
          _socket = null;
        },
        onError: (_) {
          _socket = null;
        },
        cancelOnError: true,
      );

      return true;
    } catch (_) {
      _socket = null;
      return false;
    }
  }

  void sendRaw(String jsonString) {
    _socket?.add(jsonString);
  }

  void send(String message) {
    _socket?.add(message);
  }

  String pack(String encryptedBase64) {
    return jsonEncode({
      "type": "msg",
      "payload": encryptedBase64,
    });
  }

  String? unpackPayload(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is Map<String, dynamic> && obj["type"] == "msg") {
        return obj["payload"] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> dispose() async {
    await _socket?.close();
    _socket = null;
    await _incomingController.close();
  }
}