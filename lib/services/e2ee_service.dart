import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class E2EEService {
  final keyExchange = X25519();
  final cipher = AesGcm.with256bits();

  late SimpleKeyPair myKeyPair;
  late SimplePublicKey myPublicKey;

  SecretKey? _sharedSecret;

  Future<void> generateKeyPair() async {
    myKeyPair = await keyExchange.newKeyPair();
    myPublicKey = await myKeyPair.extractPublicKey();
  }

  /// ✅ Copy this and send to peer
  String exportMyPublicKeyBase64() {
    return base64Encode(myPublicKey.bytes);
  }

  /// ✅ Paste peer public key here
  Future<void> setPeerPublicKeyBase64(String peerKeyBase64) async {
    final peerBytes = base64Decode(peerKeyBase64.trim());
    final peerPublicKey = SimplePublicKey(peerBytes, type: KeyPairType.x25519);

    _sharedSecret = await keyExchange.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: peerPublicKey,
    );
  }

  bool get isReady => _sharedSecret != null;

  Future<String> encrypt(String message) async {
    if (_sharedSecret == null) {
      throw StateError("Shared secret not ready. Set peer key first.");
    }

    final nonce = cipher.newNonce();
    final secretBox = await cipher.encrypt(
      utf8.encode(message),
      secretKey: _sharedSecret!,
      nonce: nonce,
    );

    // Pack: nonce(12) + cipherText + mac(16)
    final combined = nonce + secretBox.cipherText + secretBox.mac.bytes;
    return base64Encode(combined);
  }

  Future<String> decrypt(String encryptedMessageBase64) async {
    if (_sharedSecret == null) {
      throw StateError("Shared secret not ready. Set peer key first.");
    }

    final combined = base64Decode(encryptedMessageBase64.trim());

    final nonce = combined.sublist(0, 12);
    final macBytes = combined.sublist(combined.length - 16);
    final cipherText = combined.sublist(12, combined.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearBytes = await cipher.decrypt(
      secretBox,
      secretKey: _sharedSecret!,
    );

    return utf8.decode(clearBytes);
  }
}