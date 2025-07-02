// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// import 'simple_local_auth_method_channel.dart';

// abstract class SimpleLocalAuthPlatform extends PlatformInterface {
//   /// Constructs a SimpleLocalAuthPlatform.
//   SimpleLocalAuthPlatform() : super(token: _token);

//   static final Object _token = Object();

//   static SimpleLocalAuthPlatform _instance = MethodChannelSimpleLocalAuth();

//   /// The default instance of [SimpleLocalAuthPlatform] to use.
//   ///
//   /// Defaults to [MethodChannelSimpleLocalAuth].
//   static SimpleLocalAuthPlatform get instance => _instance;

//   /// Platform-specific implementations should set this with their own
//   /// platform-specific class that extends [SimpleLocalAuthPlatform] when
//   /// they register themselves.
//   static set instance(SimpleLocalAuthPlatform instance) {
//     PlatformInterface.verifyToken(instance, _token);
//     _instance = instance;
//   }

//   Future<String?> getPlatformVersion() {
//     throw UnimplementedError('platformVersion() has not been implemented.');
//   }
// }
