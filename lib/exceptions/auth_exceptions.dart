import 'package:flutter/services.dart';
import 'package:simple_local_auth/models/auth_results.dart';

class BiometricAuthException implements Exception {
  final String message;
  final BiometricError error;

  BiometricAuthException(this.error, [this.message = '']);

  factory BiometricAuthException.fromPlatformException(PlatformException e) {
    return BiometricAuthException(
      BiometricError.fromCode(e.code),
      e.message ?? 'Biometric authentication failed',
    );
  }

  @override
  String toString() => 'BiometricAuthException: $message (${error.name})';
}

extension BiometricErrorExtension on BiometricError {
  static BiometricError fromCode(String code) {
    switch (code) {
      case 'LOCKED_OUT':
        return BiometricError.lockedOut;
      case 'LOCKED_OUT_PERMANENT':
        return BiometricError.lockedOutPermanent;
      case 'NOT_AVAILABLE':
        return BiometricError.notAvailable;
      case 'NOT_ENROLLED':
        return BiometricError.notEnrolled;
      case 'NO_HARDWARE':
        return BiometricError.noHardware;
      case 'USER_CANCELED':
        return BiometricError.userCanceled;
      default:
        return BiometricError.unknown;
    }
  }
}