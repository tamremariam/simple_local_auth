import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simple_local_auth/models/auth_results.dart';
import 'package:simple_local_auth/simple_local_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SimpleLocalAuth Integration Tests', () {
    testWidgets('Check biometric availability', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FutureBuilder<bool>(
                // Access isAvailable through the class, not an instance
                future: SimpleLocalAuth.isAvailable,
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? 'Available' : 'Not Available');
                },
              ),
            ),
          ),
        ),
      );

      // Verify the initial state
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('Authentication flow', (WidgetTester tester) async {
      final channel = MethodChannel('simple_local_auth');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'authenticate') {
              return true;
            }
            if (methodCall.method == 'getAvailabilityDetails') {
              return {
                'hasHardware': true,
                'hasEnrolledBiometrics': true,
                'isFingerprintAvailable': true,
                'isFaceAvailable': false,
              };
            }
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder<BiometricAvailability>(
              future: SimpleLocalAuth.getAvailabilityDetails(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      Text(
                        'Fingerprint: ${snapshot.data!.isFingerprintAvailable}',
                      ),
                      Text('Face: ${snapshot.data!.isFaceAvailable}'),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await SimpleLocalAuth.authenticate(
                            reason: 'Test',
                          );
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: Text(
                                result.success ? 'Success' : 'Failed',
                              ),
                            ),
                          );
                        },
                        child: const Text('Authenticate'),
                      ),
                    ],
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Fingerprint: true'), findsOneWidget);
      expect(find.text('Face: false'), findsOneWidget);

      await tester.tap(find.text('Authenticate'));
      await tester.pumpAndSettle();
      expect(find.text('Success'), findsOneWidget);
    });
  });
}
