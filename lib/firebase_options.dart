// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwYa-Z4yJg6a22IsVsCr7B4XcK6vnictE',
    appId: '1:859297535236:web:3eaade70ebb9e8de646c51',
    messagingSenderId: '859297535236',
    projectId: 'enlighlearn',
    authDomain: 'enlighlearn.firebaseapp.com',
    storageBucket: 'enlighlearn.firebasestorage.app',
    measurementId: 'G-LF8EVVRKLD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7jeXw9LDQ4jb-TizL57YmGEewe9Km_rg',
    appId: '1:859297535236:android:f93150e4d733d3e1646c51',
    messagingSenderId: '859297535236',
    projectId: 'enlighlearn',
    storageBucket: 'enlighlearn.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDweiMLaNQ9jt6w-7Ve6T6tIIQ-rhMmNcA',
    appId: '1:859297535236:ios:ca95cf583c4a441b646c51',
    messagingSenderId: '859297535236',
    projectId: 'enlighlearn',
    storageBucket: 'enlighlearn.firebasestorage.app',
    iosBundleId: 'com.example.myEnglishApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDweiMLaNQ9jt6w-7Ve6T6tIIQ-rhMmNcA',
    appId: '1:859297535236:ios:ca95cf583c4a441b646c51',
    messagingSenderId: '859297535236',
    projectId: 'enlighlearn',
    storageBucket: 'enlighlearn.firebasestorage.app',
    iosBundleId: 'com.example.myEnglishApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBwYa-Z4yJg6a22IsVsCr7B4XcK6vnictE',
    appId: '1:859297535236:web:0c4595f6aa7516ed646c51',
    messagingSenderId: '859297535236',
    projectId: 'enlighlearn',
    authDomain: 'enlighlearn.firebaseapp.com',
    storageBucket: 'enlighlearn.firebasestorage.app',
    measurementId: 'G-SNZNTSTLM5',
  );
}
