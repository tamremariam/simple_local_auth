import 'package:flutter/services.dart';
import 'package:simple_local_auth/models/auth_results.dart';
import 'package:simple_local_auth/simple_local_auth.dart';

// Extension to enable testing (add to your SimpleLocalAuth class)
extension TestExtensions on SimpleLocalAuth {
  void setMethodChannel(MethodChannel channel) {
    // This requires modifying SimpleLocalAuth to expose the channel
    // or have a setter for testing purposes
    SimpleLocalAuth.channel = channel;
  }
}

// Helper to create platform exceptions
PlatformException createAuthException(String code, {String? message}) {
  return PlatformException(
    code: code,
    message: message ?? 'Test error',
    details: null,
  );
}

// Test data generators
BiometricAvailability createTestAvailability({
  bool hasHardware = true,
  bool hasEnrolled = true,
  bool hasFingerprint = true,
  bool hasFace = false,
}) {
  return BiometricAvailability(
    hasHardware: hasHardware,
    hasEnrolledBiometrics: hasEnrolled,
    isFingerprintAvailable: hasFingerprint,
    isFaceAvailable: hasFace,
  );
}
