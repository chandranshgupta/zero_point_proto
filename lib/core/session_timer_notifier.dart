import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/identity_service.dart';

class SessionTimerNotifier extends ChangeNotifier {
  SessionTimerNotifier._();
  static final SessionTimerNotifier instance = SessionTimerNotifier._();

  final IdentityService _identity = IdentityService.instance;
  Timer? _timer;
  int _remainingSeconds = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get isAlive => _remainingSeconds > 0;

  Future<void> initialize() async {
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await refresh();
    });
  }

  Future<void> refresh() async {
    _remainingSeconds = await _identity.remainingSeconds();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}