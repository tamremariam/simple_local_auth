import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_local_auth/simple_local_auth.dart';
import 'package:simple_local_auth/models/auth_results.dart';
import 'package:simple_local_auth/exceptions/auth_exceptions.dart';

@GenerateMocks([MethodChannel])
import 'simple_local_auth_test.mocks.dart';

void main() {
  late MockMethodChannel mockChannel;

  setUp(() {
    mockChannel = MockMethodChannel();
    SimpleLocalAuth.channel = mockChannel;
  });

  group('Authentication', () {
    test('authenticate passes correct parameters to platform', () async {
      // Arrange
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenAnswer((_) async => true);

      // Act
      await SimpleLocalAuth.authenticate(
        reason: 'Secure Access',
        preferredType: BiometricType.face,
        allowDeviceCredential: true,
        cancelButton: 'Cancel',
      );

      // Assert - Verify all parameters including defaults
      verify(
        mockChannel.invokeMethod('authenticate', {
          'reason': 'Secure Access',
          'preferredType': 'face', // Converted from enum
          'allowDeviceCredential': true,
          'title': 'Authentication required', // Default value
          'subtitle': null, // Default value
          'description': '', // Default value
          'cancelButton': 'Cancel',
          'confirmationRequired': null, // Default value
        }),
      );
    });

    test('authenticate with custom parameters', () async {
      // Arrange
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenAnswer((_) async => true);

      // Act
      await SimpleLocalAuth.authenticate(
        reason: 'Bank Login',
        preferredType: BiometricType.fingerprint,
        allowDeviceCredential: false,
        title: 'Bank Authentication',
        subtitle: 'Verify your identity',
        description: 'Required for transaction',
        cancelButton: 'Back',
        confirmationRequired: 'Confirm fingerprint',
      );

      // Assert
      verify(
        mockChannel.invokeMethod('authenticate', {
          'reason': 'Bank Login',
          'preferredType': 'fingerprint',
          'allowDeviceCredential': false,
          'title': 'Bank Authentication',
          'subtitle': 'Verify your identity',
          'description': 'Required for transaction',
          'cancelButton': 'Back',
          'confirmationRequired': 'Confirm fingerprint',
        }),
      );
    });

    test('authenticate handles platform exceptions', () async {
      // Arrange
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenThrow(PlatformException(code: 'LOCKED_OUT'));

      // Act
      final result = await SimpleLocalAuth.authenticate(reason: 'Test');

      // Assert
      expect(result.success, false);
      expect(result.error, BiometricError.lockedOut);
    });
  });

  test('authenticate passes correct parameters to platform', () async {
    // Arrange
    when(
      mockChannel.invokeMethod<bool>('authenticate', any),
    ).thenAnswer((_) async => true);

    // Act
    await SimpleLocalAuth.authenticate(
      reason: 'Secure Access',
      preferredType: BiometricType.face,
      allowDeviceCredential: true,
      cancelButton: 'Cancel',
    );

    // Assert - Verify all parameters in a single call
    verify(
      mockChannel.invokeMethod(
        'authenticate',
        argThat(
          allOf([
            containsPair('reason', 'Secure Access'),
            containsPair('preferredType', 'face'),
            containsPair('allowDeviceCredential', true),
            containsPair('cancelButton', 'Cancel'),
            containsPair('title', 'Authentication required'), // default
            containsPair('subtitle', null), // default
            containsPair('description', ''), // default
            containsPair('confirmationRequired', null), // default
          ]),
        ),
      ),
    );
  });

  group('Biometric Type Checks', () {
    test(
      'isBiometricAvailable returns correct value for fingerprint',
      () async {
        when(
          mockChannel.invokeMethod<bool>('isBiometricTypeAvailable', any),
        ).thenAnswer((_) async => true);

        expect(
          await SimpleLocalAuth.isBiometricAvailable(BiometricType.fingerprint),
          isTrue,
        );
      },
    );

    test('isBiometricAvailable handles platform errors', () async {
      when(
        mockChannel.invokeMethod<bool>('isBiometricTypeAvailable', any),
      ).thenThrow(PlatformException(code: 'ERROR'));

      expect(
        await SimpleLocalAuth.isBiometricAvailable(BiometricType.face),
        isFalse,
      );
    });
  });

  group('Error Handling', () {
    test('converts platform exceptions to BiometricAuthException', () async {
      when(
        mockChannel.invokeMethod<Map>('getAvailabilityDetails'),
      ).thenThrow(PlatformException(code: 'NOT_AVAILABLE'));

      expect(
        () => SimpleLocalAuth.getAvailabilityDetails(),
        throwsA(isA<BiometricAuthException>()),
      );
    });

    test('includes error details in BiometricAuthResult', () async {
      when(mockChannel.invokeMethod<bool>('authenticate', any)).thenThrow(
        PlatformException(code: 'LOCKED_OUT', message: 'Too many attempts'),
      );

      final result = await SimpleLocalAuth.authenticate(reason: 'Test');
      expect(result.errorDetails, 'Too many attempts');
    });
  });
}
