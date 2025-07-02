enum BiometricType { fingerprint, face, any }

enum BiometricError {
  lockedOut,
  lockedOutPermanent,
  notAvailable,
  notEnrolled,
  noHardware,
  authenticationFailed,
  userCanceled,
  unknown;

  factory BiometricError.fromCode(String code) {
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

class BiometricAvailability {
  final bool hasHardware;
  final bool hasEnrolledBiometrics;
  final bool isFingerprintAvailable;
  final bool isFaceAvailable;

  const BiometricAvailability({
    required this.hasHardware,
    required this.hasEnrolledBiometrics,
    required this.isFingerprintAvailable,
    required this.isFaceAvailable,
  });

  factory BiometricAvailability.fromMap(Map<String, dynamic> map) {
    return BiometricAvailability(
      hasHardware: map['hasHardware'] ?? false,
      hasEnrolledBiometrics: map['hasEnrolledBiometrics'] ?? false,
      isFingerprintAvailable: map['isFingerprintAvailable'] ?? false,
      isFaceAvailable: map['isFaceAvailable'] ?? false,
    );
  }
}

class BiometricAuthResult {
  final bool success;
  final BiometricError? error;
  final String? errorDetails;

  const BiometricAuthResult({
    required this.success,
    this.error,
    this.errorDetails,
  });
}
