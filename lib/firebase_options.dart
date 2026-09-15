import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWLEYOowUF_3zK9OdSvvn3F0Jm8UpfAPw',
    appId: '1:162484921989:android:2f34f5a9751110b72d2bec',
    messagingSenderId: '162484921989',
    projectId: 'rpd-sangathan',
    storageBucket: 'rpd-sangathan.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAufCoFQJB4TEUrttqdW5oJz-9tZF4SvI0',
    appId: '1:162484921989:ios:9250fe7d8ae715c92d2bec',
    messagingSenderId: '162484921989',
    projectId: 'rpd-sangathan',
    storageBucket: 'rpd-sangathan.firebasestorage.app',
    iosBundleId: 'in.rpd.rpdApp',
  );
}
