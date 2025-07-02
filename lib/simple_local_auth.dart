// import 'simple_local_auth_platform_interface.dart';

// class SimpleLocalAuth {
//   Future<String?> getPlatformVersion() {
//     return SimpleLocalAuthPlatform.instance.getPlatformVersion();
//   }
// }
// library simple_local_auth;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:simple_local_auth/exceptions/auth_exceptions.dart';
import 'package:simple_local_auth/models/auth_results.dart';

class SimpleLocalAuth {
  static MethodChannel _channel = MethodChannel('simple_local_auth');

  // Add this setter for testing
  static set channel(MethodChannel channel) {
    _channel = channel;
  }

  /// Checks if any biometric authentication is available
  static Future<bool> get isAvailable async {
    try {
      return await _channel.invokeMethod('isBiometricAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Gets detailed availability information
  static Future<BiometricAvailability> getAvailabilityDetails() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAvailabilityDetails');
      return BiometricAvailability.fromMap(
        Map<String, dynamic>.from(result ?? {}),
      );
    } on PlatformException catch (e) {
      throw BiometricAuthException.fromPlatformException(e);
    }
  }

  /// Authenticates with biometrics
  static Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate',
    BiometricType preferredType = BiometricType.any,
    bool allowDeviceCredential = false,
    String cancelButton = 'Cancel',
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('authenticate', {
        'reason': reason,
        'preferredType': preferredType.toString().split('.').last,
        'allowDeviceCredential': allowDeviceCredential,
        'cancelButton': cancelButton,
      });

      return BiometricAuthResult(
        success: success ?? false,
        error: success == true ? null : BiometricError.unknown,
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        success: false,
        error: BiometricError.fromCode(e.code),
        errorDetails: e.message,
      );
    }
  }

  /// Checks if specific biometric type is available
  static Future<bool> isBiometricAvailable(BiometricType type) async {
    try {
      return await _channel.invokeMethod<bool>('isBiometricTypeAvailable', {
            'type': type.toString().split('.').last,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
