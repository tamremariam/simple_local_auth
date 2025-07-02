import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_local_auth/simple_local_auth.dart';
import 'package:simple_local_auth/models/auth_results.dart';
import 'package:simple_local_auth/exceptions/auth_exceptions.dart';

@GenerateMocks([MethodChannel])
import 'simple_local_auth_test.mocks.dart';
import 'test_utils.dart';

void main() {
  late SimpleLocalAuth auth;
  late MockMethodChannel mockChannel;

  setUp(() {
    mockChannel = MockMethodChannel();
    auth = SimpleLocalAuth();
    // This requires adding a setter for the channel in your SimpleLocalAuth class
    auth.setMethodChannel(mockChannel);
  });

  group('Availability Checks', () {
    test('isAvailable returns true when biometric is available', () async {
      when(
        mockChannel.invokeMethod('isBiometricAvailable'),
      ).thenAnswer((_) async => true);

      expect(await SimpleLocalAuth.isAvailable, isTrue);
    });

    test('isAvailable returns false when biometric is unavailable', () async {
      when(
        mockChannel.invokeMethod('isBiometricAvailable'),
      ).thenAnswer((_) async => false);

      expect(await SimpleLocalAuth.isAvailable, isFalse);
    });

    test('getAvailabilityDetails returns correct data structure', () async {
      final testData = {
        'hasHardware': true,
        'hasEnrolledBiometrics': true,
        'isFingerprintAvailable': true,
        'isFaceAvailable': false,
      };
      when(
        mockChannel.invokeMethod<Map>('getAvailabilityDetails'),
      ).thenAnswer((_) async => testData);

      final result = await SimpleLocalAuth.getAvailabilityDetails();

      expect(result, isA<BiometricAvailability>());
      expect(result.hasHardware, true);
      expect(result.isFaceAvailable, false);
    });
  });

  group('Authentication', () {
    test('authenticate returns success on successful auth', () async {
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenAnswer((_) async => true);

      final result = await SimpleLocalAuth.authenticate(reason: 'Test');
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('authenticate handles platform exceptions', () async {
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenThrow(PlatformException(code: 'LOCKED_OUT'));

      final result = await SimpleLocalAuth.authenticate(reason: 'Test');
      expect(result.success, isFalse);
      expect(result.error, BiometricError.lockedOut);
    });

    test('authenticate passes correct parameters to platform', () async {
      when(
        mockChannel.invokeMethod<bool>('authenticate', any),
      ).thenAnswer((_) async => true);

      await SimpleLocalAuth.authenticate(
        reason: 'Secure Access',
        preferredType: BiometricType.face,
        allowDeviceCredential: true,
        cancelButton: 'Cancel',
      );

      verify(
        mockChannel.invokeMethod('authenticate', {
          'reason': 'Secure Access',
          'preferredType': 'face',
          'allowDeviceCredential': true,
          'cancelButton': 'Cancel',
        }),
      );
    });
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

      expect(await SimpleLocalAuth.isBiometricAvailable(BiometricType.face), isFalse);
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
