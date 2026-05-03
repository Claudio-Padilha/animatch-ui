// Generated from google-services.json — update if Firebase project changes.
// iOS options are omitted until iOS push notifications are implemented.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not configured for Firebase.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase options are not configured yet. '
          'Add GoogleService-Info.plist and re-run flutterfire configure on macOS.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvCNoknoZIt0QtKrUSsdv8R4_LNz5ce1A',
    appId: '1:212882547100:android:66cd7a1aa939cfcaaae859',
    messagingSenderId: '212882547100',
    projectId: 'animatch-2f2e1',
    storageBucket: 'animatch-2f2e1.firebasestorage.app',
  );
}
