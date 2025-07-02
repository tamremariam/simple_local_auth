// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';

// import 'simple_local_auth_platform_interface.dart';

// /// An implementation of [SimpleLocalAuthPlatform] that uses method channels.
// class MethodChannelSimpleLocalAuth extends SimpleLocalAuthPlatform {
//   /// The method channel used to interact with the native platform.
//   @visibleForTesting
//   final methodChannel = const MethodChannel('simple_local_auth');

//   @override
//   Future<String?> getPlatformVersion() async {
//     final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
//     return version;
//   }
// }
