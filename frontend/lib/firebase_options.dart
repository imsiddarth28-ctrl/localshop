// File generated for The Local Shop Firebase integration.
// DO NOT EDIT MANUALLY unless updating Firebase projects.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCUDLs1xRFagv0qDVPRfOzpwCNhFPZnBaw',
    appId: '1:439547890410:web:27dda4b20e3452b5f0a593',
    messagingSenderId: '439547890410',
    projectId: 'localshop-47cf1',
    storageBucket: 'localshop-47cf1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUDLs1xRFagv0qDVPRfOzpwCNhFPZnBaw',
    appId: '1:439547890410:android:27dda4b20e3452b5f0a593',
    messagingSenderId: '439547890410',
    projectId: 'localshop-47cf1',
    storageBucket: 'localshop-47cf1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUDLs1xRFagv0qDVPRfOzpwCNhFPZnBaw',
    appId: '1:439547890410:ios:27dda4b20e3452b5f0a593',
    messagingSenderId: '439547890410',
    projectId: 'localshop-47cf1',
    storageBucket: 'localshop-47cf1.firebasestorage.app',
  );
}
