import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

class P2PWsTransport {
  HttpServer? _server;
  WebSocket? _serverSocket;
  WebSocketChannel? _clientChannel;

  final _incomingController = StreamController<String>.broadcast();
  Stream<String> get incoming => _incomingController.stream;

  bool get isServerRunning => _server != null;
  bool get isConnected => _serverSocket != null || _clientChannel != null;

  // Start WS server on this device
  Future<void> startServer({int port = 4040}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final ws = await WebSocketTransformer.upgrade(request);
        _serverSocket = ws;

        ws.listen((data) {
          _incomingController.add(data.toString());
        }, onDone: () {
          _serverSocket = null;
        });
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    });
  }

  // Connect as client to peer IP
  Future<void> connectToServer(String ip, {int port = 4040}) async {
    final uri = Uri.parse('ws://$ip:$port');
    _clientChannel = WebSocketChannel.connect(uri);

    _clientChannel!.stream.listen((data) {
      _incomingController.add(data.toString());
    }, onDone: () {
      _clientChannel = null;
    });
  }

  // Send message string (we will send encrypted base64)
  void send(String message) {
    if (_serverSocket != null) {
      _serverSocket!.add(message);
      return;
    }
    _clientChannel?.sink.add(message);
  }

  Future<void> dispose() async {
    await _incomingController.close();
    await _serverSocket?.close();
    await _clientChannel?.sink.close();
    await _server?.close(force: true);
  }

  /// Helper: find your local IP (often 10.0.2.15 on emulator)
  Future<List<String>> getLocalIps() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final ips = <String>[];
    for (final i in interfaces) {
      for (final addr in i.addresses) {
        ips.add(addr.address);
      }
    }
    return ips;
  }

  /// JSON wrapper so we can extend later
  String pack(String encryptedBase64) {
    return jsonEncode({"type": "msg", "payload": encryptedBase64});
  }

  String? unpackPayload(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is Map && obj["type"] == "msg") {
        return obj["payload"] as String?;
      }
    } catch (_) {}
    return null;
  }
}