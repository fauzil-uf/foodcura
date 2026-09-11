// File generated for Firebase Options
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
//// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLv-Fd8QgczajbYP043SUqMIu14QFK4mo',
    appId: '1:767149958522:android:ad8547f0f615682f19a2c3',
    messagingSenderId: '767149958522',
    projectId: 'foodcura-c2a5c',
    storageBucket: 'foodcura-c2a5c.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLv-Fd8QgczajbYP043SUqMIu14QFK4mo',
    appId: '1:767149958522:web:ad8547f0f615682f19a2c3',
    messagingSenderId: '767149958522',
    projectId: 'foodcura-c2a5c',
    storageBucket: 'foodcura-c2a5c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLv-Fd8QgczajbYP043SUqMIu14QFK4mo',
    appId: '1:767149958522:ios:ad8547f0f615682f19a2c3',
    messagingSenderId: '767149958522',
    projectId: 'foodcura-c2a5c',
    storageBucket: 'foodcura-c2a5c.firebasestorage.app',
    iosBundleId: 'com.fauzil.foodcura',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLv-Fd8QgczajbYP043SUqMIu14QFK4mo',
    appId: '1:767149958522:ios:ad8547f0f615682f19a2c3',
    messagingSenderId: '767149958522',
    projectId: 'foodcura-c2a5c',
    storageBucket: 'foodcura-c2a5c.firebasestorage.app',
    iosBundleId: 'com.fauzil.foodcura',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCLv-Fd8QgczajbYP043SUqMIu14QFK4mo',
    appId: '1:767149958522:web:ad8547f0f615682f19a2c3',
    messagingSenderId: '767149958522',
    projectId: 'foodcura-c2a5c',
    storageBucket: 'foodcura-c2a5c.firebasestorage.app',
  );
}
