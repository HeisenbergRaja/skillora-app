import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase options.
///
/// Run `flutterfire configure` to replace this file with real values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQJA0n4I_zFkHDOVpYCdz7C0zoKfR2yLw',
    appId: '1:1066596804618:web:62ac17eb2a6616143097f3',
    messagingSenderId: '1066596804618',
    projectId: 'skillora-dc024',
    authDomain: 'skillora-dc024.firebaseapp.com',
    storageBucket: 'skillora-dc024.firebasestorage.app',
    measurementId: 'G-RTESJY16WE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAJ7-NYmjVEdrphXZZ9wbZLrsuEktmOi0',
    appId: '1:1066596804618:android:dc8a0c49772d64333097f3',
    messagingSenderId: '1066596804618',
    projectId: 'skillora-dc024',
    storageBucket: 'skillora-dc024.firebasestorage.app',
  );
}
