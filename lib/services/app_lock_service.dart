import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kind of verification the app requires before showing private data.
enum LockType { none, biometric, pin }

/// Unified app-lock service. Supports the phone's native biometric prompt and
/// a local 4-digit PIN. The PIN is hashed and stored on-device only (keyed by
/// user) and never leaves the device.
class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? _lastSuccessfulAuthentication;

  /// True right after a successful verification. Used to avoid re-prompting
  /// when the user only briefly leaves and returns to the app.
  bool get wasRecentlyAuthenticated {
    final last = _lastSuccessfulAuthentication;
    return last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric sheet. `biometricOnly: false` lets the operating
  /// system fall back to its own PIN/pattern if biometrics fail or are not
  /// enrolled.
  Future<bool> authenticateBiometric() async {
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock your private finance data',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (success) _lastSuccessfulAuthentication = DateTime.now();
      return success;
    } catch (_) {
      return false;
    }
  }

  static String _pinKey(String uid) => 'app_lock.pin.$uid';

  static String _lockTypeKey(String uid) => 'app_lock.type.$uid';

  /// The lock method is stored **on-device only** (keyed by user), never on the
  /// server. That way a fresh sign-in, a new device, or a reinstall always
  /// starts with [LockType.none] and the lock only applies after the user sets
  /// it again from the privacy settings.
  Future<LockType> loadLockType(String uid) async {
    if (uid.isEmpty) return LockType.none;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_lockTypeKey(uid));
    if (stored == null || stored.isEmpty) return LockType.none;
    return LockType.values.firstWhere(
      (type) => type.name == stored,
      orElse: () => LockType.none,
    );
  }

  Future<void> saveLockType(String uid, LockType type) async {
    if (uid.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lockTypeKey(uid), type.name);
  }

  Future<void> clearLockType(String uid) async {
    if (uid.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lockTypeKey(uid));
  }

  Future<bool> hasPin(String uid) async {
    if (uid.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_pinKey(uid));
    return stored != null && stored.isNotEmpty;
  }

  Future<void> setPin(String uid, String pin) async {
    if (uid.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pinKey(uid), _hashPin(uid, pin));
  }

  Future<bool> verifyPin(String uid, String pin) async {
    if (uid.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_pinKey(uid));
    if (stored == null || stored.isEmpty) return false;
    if (stored == _hashPin(uid, pin)) {
      _lastSuccessfulAuthentication = DateTime.now();
      return true;
    }
    return false;
  }

  Future<void> clearPin(String uid) async {
    if (uid.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pinKey(uid));
  }

  static String _hashPin(String uid, String pin) {
    final digest = sha256.convert(utf8.encode('pj1-lock:$uid:$pin'));
    return digest.toString();
  }
}
