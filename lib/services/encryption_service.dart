import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // Demo-only key (NOT real E2EE). For hackathon demo UI only.
  final _key = Key.fromUtf8('1234567890123456'); // 16 chars = AES-128
  final _iv = IV.fromLength(16);

  String encryptMessage(String message) {
    final encrypter = Encrypter(AES(_key));
    final encrypted = encrypter.encrypt(message, iv: _iv);
    return encrypted.base64;
  }

  String decryptMessage(String encryptedMessage) {
    final encrypter = Encrypter(AES(_key));
    return encrypter.decrypt(Encrypted.fromBase64(encryptedMessage), iv: _iv);
  }
}