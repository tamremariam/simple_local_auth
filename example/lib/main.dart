import 'package:flutter/material.dart';
import 'package:simple_local_auth/models/auth_results.dart';
import 'package:simple_local_auth/simple_local_auth.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BiometricAuthApp());
}

class BiometricAuthApp extends StatelessWidget {
  const BiometricAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioAuth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthHomeScreen extends StatefulWidget {
  const AuthHomeScreen({super.key});

  @override
  State<AuthHomeScreen> createState() => _AuthHomeScreenState();
}

class _AuthHomeScreenState extends State<AuthHomeScreen> {
  final SimpleLocalAuth auth = SimpleLocalAuth();
  BiometricAvailability? _availability;
  bool _isAuthenticating = false;
  String _authStatus = '';
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final availability = await SimpleLocalAuth.getAvailabilityDetails();
      setState(() {
        _availability = availability;
        _authStatus = availability.hasHardware
            ? 'Biometrics available'
            : 'No biometric hardware';
        _statusColor = availability.hasHardware ? Colors.green : Colors.orange;
      });
    } on PlatformException catch (e) {
      setState(() {
        _authStatus = 'Error: ${e.message}';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
      _statusColor = Colors.black;
    });

    try {
      final result = await SimpleLocalAuth.authenticate(
        reason: 'Verify your identity',
        cancelButton: 'Not now',
      );

      setState(() {
        _authStatus = result.success ? 'Success!' : 'Authentication failed';
        _statusColor = result.success ? Colors.green : Colors.red;
      });

      if (result.success) {
        await _showSuccessDialog();
      }
    } on PlatformException catch (e) {
      setState(() {
        _authStatus = 'Error: ${e.message}';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authenticated'),
        content: const Text('You have successfully authenticated!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BioAuth Demo'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Biometric Icon
            Icon(Icons.fingerprint, size: 80, color: _statusColor),
            const SizedBox(height: 20),

            // Status Text
            Text(
              _authStatus,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
            const SizedBox(height: 30),

            // Biometric Capabilities
            if (_availability != null) ...[
              _buildCapabilityItem(
                'Hardware Available',
                _availability!.hasHardware,
              ),
              _buildCapabilityItem(
                'Biometrics Enrolled',
                _availability!.hasEnrolledBiometrics,
              ),
              _buildCapabilityItem(
                'Fingerprint Available',
                _availability!.isFingerprintAvailable,
              ),
              _buildCapabilityItem(
                'Face ID Available',
                _availability!.isFaceAvailable,
              ),
              const SizedBox(height: 30),
            ],

            // Authenticate Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: _isAuthenticating
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.fingerprint),
                label: Text(
                  _isAuthenticating ? 'Authenticating...' : 'Authenticate',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Check Again Button
            TextButton(
              onPressed: _checkBiometrics,
              child: const Text('Check Biometrics Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(String title, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.error,
            color: isAvailable ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Text(title),
          const Spacer(),
          Text(isAvailable ? 'Yes' : 'No'),
        ],
      ),
    );
  }
}
