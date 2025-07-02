// lib/src/simple_local_auth_impl.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:simple_local_auth/models/biometric_availability.dart';
import '../exceptions/auth_exceptions.dart';
import '../models/auth_results.dart';
import 'types.dart';

class SimpleLocalAuth {
  static MethodChannel _channel = const MethodChannel('simple_local_auth');

  // For testing purposes
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

  static Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate',
    BiometricType preferredType = BiometricType.any,
    bool allowDeviceCredential = false,
    String title = 'Authentication required',
    String? subtitle,
    String description = '',
    String cancelButton = 'Cancel',
    String? confirmationRequired,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('authenticate', {
        'reason': reason,
        'preferredType': preferredType.name,
        'allowDeviceCredential': allowDeviceCredential,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'cancelButton': cancelButton,
        'confirmationRequired': confirmationRequired,
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
            'type': type.name,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
