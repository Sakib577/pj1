import 'package:local_auth/local_auth.dart';

/// Uses the platform's configured biometric method. The operating system
/// chooses fingerprint, face, or another supported biometric automatically.
class BiometricLockService {
  BiometricLockService._();

  static final BiometricLockService instance = BiometricLockService._();
  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? _lastSuccessfulAuthentication;

  bool get wasRecentlyAuthenticated {
    final last = _lastSuccessfulAuthentication;
    return last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 5);
  }

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock your private finance data',
        options: const AuthenticationOptions(
          biometricOnly: true,
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
}
