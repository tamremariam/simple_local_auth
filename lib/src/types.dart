// lib/src/types.dart
enum BiometricType {
  any('any'),
  fingerprint('fingerprint'),
  face('face');

  final String name;
  const BiometricType(this.name);
}

enum BiometricError {
  lockedOut('lockedOut'),
  lockedOutPermanent('lockedOutPermanent'),
  notAvailable('notAvailable'),
  notEnrolled('notEnrolled'),
  noHardware('noHardware'),
  authenticationFailed('authenticationFailed'),
  userCanceled('userCanceled'),
  unknown('unknown');

  final String name;
  const BiometricError(this.name);

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
