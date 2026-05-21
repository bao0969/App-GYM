import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ Web config — GymSync Web (gymsync-205fd)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6AYg6i-yrPVZV5LbzYEBr6HVDwzfoIpw',
    appId: '1:536782424529:web:c5347267f9408c3c7ef8f0',
    messagingSenderId: '536782424529',
    projectId: 'gymsync-205fd',
    authDomain: 'gymsync-205fd.firebaseapp.com',
    storageBucket: 'gymsync-205fd.firebasestorage.app',
    measurementId: 'G-JYYYFTBL9T',
  );

  // ✅ Windows — dùng cùng config web
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB6AYg6i-yrPVZV5LbzYEBr6HVDwzfoIpw',
    appId: '1:536782424529:web:c5347267f9408c3c7ef8f0',
    messagingSenderId: '536782424529',
    projectId: 'gymsync-205fd',
    authDomain: 'gymsync-205fd.firebaseapp.com',
    storageBucket: 'gymsync-205fd.firebasestorage.app',
    measurementId: 'G-JYYYFTBL9T',
  );

  // Android — cần google-services.json riêng nếu build Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6AYg6i-yrPVZV5LbzYEBr6HVDwzfoIpw',
    appId: '1:536782424529:web:c5347267f9408c3c7ef8f0',
    messagingSenderId: '536782424529',
    projectId: 'gymsync-205fd',
    storageBucket: 'gymsync-205fd.firebasestorage.app',
  );

  // iOS placeholder
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6AYg6i-yrPVZV5LbzYEBr6HVDwzfoIpw',
    appId: '1:536782424529:web:c5347267f9408c3c7ef8f0',
    messagingSenderId: '536782424529',
    projectId: 'gymsync-205fd',
    storageBucket: 'gymsync-205fd.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  // macOS placeholder
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB6AYg6i-yrPVZV5LbzYEBr6HVDwzfoIpw',
    appId: '1:536782424529:web:c5347267f9408c3c7ef8f0',
    messagingSenderId: '536782424529',
    projectId: 'gymsync-205fd',
    storageBucket: 'gymsync-205fd.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
