import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityService {

  IdentityService._internal();
  static final IdentityService instance = IdentityService._internal();

  factory IdentityService() => instance;

  static const _aliasKey = "identity_alias";
  static const _expiryKey = "identity_expiry";
  static const _secretKey = "identity_secret";

  static final RegExp _secretRegex = RegExp(r'^[0-9+\-*/.]+=$');

  /// =========================
  /// CREATE IDENTITY
  /// =========================

  Future<void> createIdentity({
    required int hours,
    String secretCode = "1234=",
  }) async {

    final prefs = await SharedPreferences.getInstance();

    final expiry =
        DateTime.now().toUtc().add(Duration(hours: hours));

    await prefs.setString(_aliasKey, _generateAlias());
    await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch);
    await prefs.setString(_secretKey, secretCode);
  }

  /// OLD METHOD SUPPORT
  Future<void> setFlushHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();

    final expiry =
        DateTime.now().toUtc().add(Duration(hours: hours));

    await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch);
  }

  /// =========================
  /// CHECK IDENTITY
  /// =========================

  Future<bool> hasValidIdentity() async {
    final expiry = await getExpiry();

    if (expiry == null) return false;

    return expiry.isAfter(DateTime.now().toUtc());
  }

  /// =========================
  /// GET ALIAS
  /// =========================

  Future<String> getAlias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aliasKey) ?? "Unknown";
  }

  /// =========================
  /// GET EXPIRY
  /// =========================

  Future<DateTime?> getExpiry() async {

    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getInt(_expiryKey);

    if (value == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(
      value,
      isUtc: true,
    );
  }

  /// =========================
  /// SESSION TIMER
  /// =========================

  Future<int> remainingSeconds() async {

    final expiry = await getExpiry();

    if (expiry == null) return 0;

    final diff =
        expiry.difference(DateTime.now().toUtc()).inSeconds;

    if (diff < 0) return 0;

    return diff;
  }

  /// =========================
  /// SECRET CODE
  /// =========================

  Future<String?> getSecretCode() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_secretKey);
  }

  Future<bool> validateSecretCode(String input) async {

    final stored = await getSecretCode();

    if (stored == null) return false;

    return input == stored;
  }

  bool isValidSecretCode(String code) {

    if (code.isEmpty) return false;

    if (!_secretRegex.hasMatch(code)) return false;

    final eqIndex = code.indexOf('=');

    return eqIndex == code.length - 1;
  }

  /// =========================
  /// DELETE IDENTITY
  /// =========================

  Future<void> flushIdentity() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_aliasKey);
    await prefs.remove(_expiryKey);
    await prefs.remove(_secretKey);
  }

  /// =========================
  /// RANDOM ALIAS
  /// =========================

  String _generateAlias() {

    const adjectives = [
      "Silent",
      "Ghost",
      "Shadow",
      "Nova",
      "Cipher",
      "Stealth",
      "Phantom",
      "Obsidian",
      "Void"
    ];

    const animals = [
      "Wolf",
      "Raven",
      "Fox",
      "Viper",
      "Tiger",
      "Panther",
      "Owl",
      "Falcon"
    ];

    final random = Random();

    final adj = adjectives[random.nextInt(adjectives.length)];
    final animal = animals[random.nextInt(animals.length)];
    final number = 100 + random.nextInt(900);

    return "$adj-$animal-$number";
  }
}