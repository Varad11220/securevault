import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Prompts the user for biometric or device passcode authentication.
/// Returns true if authenticated, false otherwise.
Future<bool> requestDeviceAuthentication({
  String reason = 'Please authenticate to continue',
}) async {
  final LocalAuthentication auth = LocalAuthentication();

  try {
    final bool isDeviceSupported = await auth.isDeviceSupported();
    final bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (!isDeviceSupported && !canCheckBiometrics) {
      return false;
    }

    final bool authenticated = await auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        useErrorDialogs: true,
        stickyAuth: false,
        biometricOnly: false,
      ),
    );

    return authenticated;
  } on PlatformException catch (e) {
    print('Auth error: ${e.code} - ${e.message}');
    return false;
  } catch (_) {
    return false;
  }
}