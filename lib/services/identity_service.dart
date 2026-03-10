import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityService {
  static const _kExpiryMs = 'identity_expiry_ms';
  static const _kAlias = 'identity_alias';

  // -------- Public API used by your screens --------

  /// Used by onboarding/dashboard: is identity present and not expired?
  Future<bool> hasValidIdentity() async {
    final expiry = await getExpiry();
    if (expiry == null) return false;
    final now = DateTime.now().toUtc();
    return expiry.isAfter(now);
  }

  /// Used by onboarding: create identity with expiry
  Future<void> createIdentity({required int hours}) async {
    await setFlushHours(hours);
    await _ensureAlias();
  }

  /// Used by dashboard: show alias
  Future<String> getAlias() async {
    final sp = await SharedPreferences.getInstance();
    final alias = sp.getString(_kAlias);
    if (alias != null && alias.isNotEmpty) return alias;
    return _generateAlias(); // fallback
  }

  /// Used by dashboard/onboarding: flush identity & state
  Future<void> flushIdentity() async {
    await flushAll();
  }

  // -------- Core methods (used by chat too) --------

  Future<void> setFlushHours(int hours) async {
    final sp = await SharedPreferences.getInstance();
    final expiry = DateTime.now().toUtc().add(Duration(hours: hours));
    await sp.setInt(_kExpiryMs, expiry.millisecondsSinceEpoch);
    await _ensureAlias();
  }

  Future<DateTime?> getExpiry() async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt(_kExpiryMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<int> remainingSeconds() async {
    final expiry = await getExpiry();
    if (expiry == null) return 0;
    final now = DateTime.now().toUtc();
    final diff = expiry.difference(now).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  Future<bool> isExpired() async {
    return (await remainingSeconds()) <= 0;
  }

  Future<void> flushAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kExpiryMs);
    await sp.remove(_kAlias);
  }

  // -------- Helpers --------

  Future<void> _ensureAlias() async {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(_kAlias);
    if (existing != null && existing.isNotEmpty) return;
    await sp.setString(_kAlias, _generateAlias());
  }

  String _generateAlias() {
    const adjectives = [
      "Neon",
      "Silent",
      "Shadow",
      "Nova",
      "Crimson",
      "Phantom",
      "Void",
      "Cipher",
      "Obsidian",
      "Frost"
    ];
    const animals = [
      "Viper",
      "Raven",
      "Fox",
      "Wolf",
      "Hawk",
      "Tiger",
      "Mantis",
      "Eel",
      "Owl",
      "Panther"
    ];
    final r = Random();
    final adj = adjectives[r.nextInt(adjectives.length)];
    final ani = animals[r.nextInt(animals.length)];
    final code = (100 + r.nextInt(900)).toString();
    return "$adj-$ani-$code";
  }
}