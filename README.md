# 🛡️ Simple Local Auth

A lightweight and developer-friendly Flutter plugin to authenticate users using local biometric methods such as **Fingerprint**, **Face ID**, and other platform-specific mechanisms.

## ✨ Features

* Check biometric hardware availability
* Detect enrolled biometrics
* Support for Fingerprint and Face ID
* Simple API to trigger biometric authentication
* Smooth integration for Android and iOS
* Supports Localization
* Customizable authentication prompts (title, reason, cancel button, etc.)

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  simple_local_auth: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## ⚙️ Platform Setup

### Android

1. Update your `android/app/build.gradle`:

```groovy
minSdkVersion 23
```

2. Add permissions to `AndroidManifest.xml` (usually not required, but ensure biometric support is enabled):

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS

1. Add the following to your `Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to authenticate the user</string>
```

2. Ensure your app has a Deployment Target of **iOS 11.0+** in `ios/Podfile`.

## 🚀 Getting Started

### Import the package

```dart
import 'package:simple_local_auth/simple_local_auth.dart';
import 'package:simple_local_auth/models/auth_results.dart';
```

### Check Biometric Availability

```dart
final availability = await SimpleLocalAuth.getAvailabilityDetails();
if (availability.hasHardware && availability.hasEnrolledBiometrics) {
  // Safe to prompt for authentication
}
```

### Authenticate User

```dart
final result = await SimpleLocalAuth.authenticate(
  reason: 'Please authenticate to proceed',
  cancelButton: 'Cancel',
);

if (result.success) {
  // Authentication successful
} else {
  // Handle failure
}
```

## 🌍 Localization & Customization

`simple_local_auth` is designed with flexibility in mind. It supports:

* Full localization of prompt messages, including:

  * Authentication reason
  * Cancel button text
  * Titles and subtitles (where supported)
* Custom display strings to enhance user experience
* Seamless integration with localization packages

This gives developers full control over how messages are shown to users, making authentication immersive, polished, and aligned with your app’s tone and branding.

## 🧪 Example App

A full-featured example is included in the `example/` directory.

Run it:

```bash
cd example
flutter run
```

The app shows:

* Biometric availability
* Authentication status
* Feedback on success/failure

## 📷 UI Preview

<p align="center">
  <img src="https://raw.githubusercontent.com/tamremariam/simple_local_auth/main/assets/Screenshot_20250702_191031.png" alt="Authentication Screenshot 1" width="300"/>
  <img src="https://raw.githubusercontent.com/tamremariam/simple_local_auth/main/assets/Screenshot_20250702_191144.png" alt="Authentication Screenshot 2" width="300"/>
</p>

## ✅ Capabilities Checked

* Hardware Availability ✅
* Biometrics Enrolled ✅
* Fingerprint Support ✅
* Face ID Support ✅

## 📌 Notes

* On some Android devices, users must manually enroll biometrics.
* On iOS, ensure Face ID/Touch ID is configured in device settings.

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Submit a pull request with a clear description

## 📄 License

MIT License

---

Built with ❤️ by \[Tamremariam Belete].

---
