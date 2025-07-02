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
