// enum BiometricError {
//   lockedOut,
//   lockedOutPermanent,
//   notAvailable,
//   notEnrolled,
//   noHardware,
//   authenticationFailed,
//   userCanceled,
//   unknown;

//   factory BiometricError.fromCode(String code) {
//     switch (code) {
//       case 'LOCKED_OUT':
//         return BiometricError.lockedOut;
//       case 'LOCKED_OUT_PERMANENT':
//         return BiometricError.lockedOutPermanent;
//       case 'NOT_AVAILABLE':
//         return BiometricError.notAvailable;
//       case 'NOT_ENROLLED':
//         return BiometricError.notEnrolled;
//       case 'NO_HARDWARE':
//         return BiometricError.noHardware;
//       case 'USER_CANCELED':
//         return BiometricError.userCanceled;
//       default:
//         return BiometricError.unknown;
//     }
//   }
// }

import 'package:simple_local_auth/src/types.dart';

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
