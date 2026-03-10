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
      final socket = await WebSocket.connect('ws://$ip:$port');
      _socket = socket;

      socket.listen(
            (data) {
          _incomingController.add(data.toString());
        },
        onDone: () {
          _socket = null;
          print('WebSocket disconnected');
        },
        onError: (e) {
          _socket = null;
          print('WebSocket error: $e');
        },
        cancelOnError: true,
      );

      print('WebSocket connected to ws://$ip:$port');
      return true;
    } catch (e) {
      _socket = null;
      print('Connect failed: $e');
      return false;
    }
  }

  void send(String message) {
    if (_socket == null) {
      print('Send failed: socket is null');
      return;
    }
    _socket!.add(message);
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
    } catch (e) {
      print("Unpack failed: $e");
    }
    return null;
  }

  Future<void> dispose() async {
    await _socket?.close();
    _socket = null;
    await _incomingController.close();
  }
}